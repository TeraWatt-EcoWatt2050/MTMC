%% Master function to do corrections for unknown freestream velocity in a MIKE3 model.

% Copyright (C) Simon Waldman / Heriot-Watt University, 2015.

% Requires MIKE Zero to be installed on the PC. Requires the DHI Matlab toolbox to be on the path.
%   Also requires my mike_tools package from https://github.com/TeraWatt-EcoWatt2050/MIKE_tools
%   The latest version of this package is available at https://github.com/TeraWatt-EcoWatt2050/MTMC

% Inputs:
%   m3fmFilename = filename of the .m3fm model definition file that will be
%       read and modified.
%   matFilename = filename of the .mat MATLAB data file that is/will be
%       used to transfer information between iterations of this function.
%       If it doesn't exist the script will assume that this is the first
%       iteration and create it.
%   Turbinedfs0Filenames = cell array of .dfs0 data files created using the
%       "Turbine output" option in a prior run. There may be more than one if
%       running in MPI mode, as MIKE will produce one file for each subdomain.
%   meshFilename = filename of the .mesh file used in the model
%   Alphadfs0Filename = filename that should be used as the base for
%       creating new .dfs0 data files containing time-varying correction
%       factors. This base will have _it1, _it2, etc., appended to signify
%       different iterations of the script.
%   SurfElevdfsuFilename = filename of a 2D .dfsu file, output from a prior run of the model,
%       that contains the "Surface elevation" item and covers the area of all the turbines.

% Outputs:
%   No outputs in MATLAB. The m3fm file is modified.

function [] = MakeCorrection( m3fmFilename, matFilename, Turbinedfs0Filenames, meshFilename, Alphadfs0Filename, SurfElevdfsuFilename )
%FIXME could read meshFilename from m3fm.
%FIXME should group input and output filenames together to rationalise.


%% Read or set up data structures

% If there's a data file from a previous iteration
if exist(matFilename, 'file')
    
    disp('Reading information from previous iteration...');
    load(matFilename);
    IterationNo = IterationNo + 1;
    disp('Expanding data structures...');
    % add a new column to various matrices that record per-iteration
    % results FIXME maybe perhaps move this to a fn?
    for a = 1:length(EWT)
        EWT(a).CurrentSpeed(:,IterationNo) = nan;
        EWT(a).CurrentDirection(:,IterationNo) = nan;
        EWT(a).CSA(:,IterationNo) = nan;
        EWT(a).Depth(:,IterationNo) = EWT(a).Depth(:,1);    %FIXME TEMPORARY. Change once I handle varying water level.
        EWT(a).DeltaZ(:, IterationNo) = EWT(a).DeltaZ(:,1);  %FIXME TEMPORARY. Change once I handle varying water level.
    end
    for t = 1:length(Turbines)
        Turbines(t).Alpha(:,IterationNo) = nan;
        Turbines(t).Force(:,IterationNo) = nan; %NB this is the force from the PREVIOUS run, so arguably it's offset by one from everything else here.
    end

else    %  this is the first iteration
    
    IterationNo = 1;
    
end

%% Setup on first iteration

if IterationNo == 1
    disp('First iteration setup...');
    
    % Read the m3fm file to get turbine locations and Ct curves, number of layers and number
    % of timesteps
    disp('Reading m3fm file...');
    caTurbineSection = MTMC.fnExtractM3FMSection( m3fmFilename, 'TURBINES' );
    NumTurbines = str2num(MTMC.fnReadDHIValue( caTurbineSection, 'number_of_turbines' ));
    
    caDomainSection = MTMC.fnExtractM3FMSection( m3fmFilename, 'DOMAIN' );
    NumLayers = str2num(MTMC.fnReadDHIValue( caDomainSection, 'number_of_layers' ));
    clear caDomainSection;
    %FIXME add checking for sigma layers and equidistant spacing. Error if
    %not.
    
    % there are, sadly, many sections labelled 'TIME'. We only want the
    % first.
    caTimeSections = MTMC.fnExtractM3FMSection( m3fmFilename, 'TIME', 'multiple' );
    NumTSs = str2num(MTMC.fnReadDHIValue( caTimeSections(:,1), 'number_of_time_steps' )) + 1;    %awkward. If there are n TSs, there are n+1 entries in dfs0 files, because TS 0 is the initial condition.
    StartTime = str2num(MTMC.fnReadDHIValue( caTimeSections(:,1),'start_time')); %will give a vector of YYYY M D h m s in double.
    TSLength = str2num(MTMC.fnReadDHIValue( caTimeSections(:,1), 'time_step_interval'));  %seconds
    clear caTimeSections;
    
    % read the mesh
    disp('Reading mesh file...');
    [et, nodes] = mzReadMesh(meshFilename);  %et = element table; nodes = nodes.
    trMesh = triangulation(et, nodes(:,1:3));   % (there's an extra fourth column in nodes that we don't want.)
    trMesh2D = triangulation(et, nodes(:,1:2)); % 2D version that doesn't have elevation info. Makes some stuff easier.
    clear et nodes;
    
    % set up Turbines data structure
    disp('Setting up data structures & finding which mesh elements turbines are in...');
    Turbines = MTMC.fnGenerateTurbinesStruct( caTurbineSection, NumTSs, trMesh2D );
  
    % set up EWT (Elements With Turbines) data structure
    EWT = MTMC.fnGenerateEWTStruct( Turbines, NumTSs, trMesh );
    NumEWT = length(EWT);
    
end

%% Read the turbines dfs0 files for flow velocities and directions at the turbines at last iteration
%  (it needs to have been run once without corrections to generate this the first time)

disp('Reading turbines output file(s) from previous model run...');
CumTurbCount = 0; %cumulative turbine count, to make sure we have the right number of them.

for f = 1:length(Turbinedfs0Filenames) %for each file
    
    [ TurbineNums, Speeds, Directions, Drag ] = MTMC.fnReadTurbinesDfs0( Turbinedfs0Filenames{f} );
    
    CumTurbCount = CumTurbCount + length(TurbineNums);
    %We now have speed and direction for turbines, but we need to store that
    %for cells. For each turbine, find the cell that it's in and store it there
    %(if the cell doesn't already have a value from a previous loop with
    %another turbine)
    
    for a = 1:length(TurbineNums)
        tno = TurbineNums(a);
        Turbines(tno).Force(:,IterationNo) = Drag(:,a);
        elno = Turbines(tno).ElementNo;
        el = find([EWT.ElementNo]==elno);   %NB will give wrong answer if any blank ElementNos. Shouldn't be, we initialised them all to nan.
        if any(isnan(EWT(el).CurrentSpeed(:,IterationNo)))
            EWT(el).CurrentSpeed(:,IterationNo) = Speeds(:,a);
            EWT(el).CurrentDirection(:,IterationNo) = Directions(:,a);
        end
    end
end

if CumTurbCount ~= NumTurbines
    error('Number of turbines read from .dfs0 does not match number given in .m3fm.');
end
clear CumTurbCount el elno TurbineNums Speeds Directions Drag;

%% Read the surface elevation dfsu and fill in depth and deltaZ from it.

EWTList = [ EWT.ElementNo ];    %this should give us a vector of the element numbers with turbines, in the right order.
SurfElevs = MTMC.fnReadSurfElevDfsu( SurfElevdfsuFilename, EWTList );

%now we have a matrix with elements as columns as time steps as rows. 
for a = 1:size(EWTList, 1)
    EWT(a).Depth(:, IterationNo) = SurfElevs(:,a) - EWT(a).SeabedElevation;
    EWT(a).DeltaZ(:, IterationNo) = EWT(a).Depth(:, IterationNo) / NumLayers;   %assumes equispaced layers.
end

%% Calculate element cross-sectional areas, deltaZ, etc. for each EWT on each TS.

disp('Calculating cross-sectional areas of mesh elements with turbines in...');
% for each element with turbine(s) in,
for el = 1:NumEWT
    for ts = 1:NumTSs   % for each timestep
        [CSA] = MTMC.fnCalcCellCSA(trMesh, EWT(el).ElementNo, EWT(el).CurrentDirection(ts, IterationNo), EWT(el).DeltaZ(ts, IterationNo));
        assert(~isnan(CSA), 'CSA returned as NaN. There''s a problem here.');
        EWT(el).CSA(ts, IterationNo) = CSA;
        clear CSA Depth DeltaZ;
    end
end

%% Calculate Cts and correction factors

disp('Calculating corrections...');
for t = 1:NumTurbines %for each turbine
   
    el = find([EWT.ElementNo]==Turbines(t).ElementNo); % find index in EWT for this element.
    
    NumLayersIntersected = MTMC.fnFindLayersForTurbine( Turbines(t).z, Turbines(t).Diameter, EWT(el).SeabedElevation, NumLayers, EWT(el).DeltaZ(:, IterationNo) );
    
    % form 1D vectors (representing timesteps) of the various parameters
    % that determine the desired corrections, then calculate them.
            %FIXME for now, assume weathervaning turbines always facing into
        %flow. When this is fixed, still need to allow for a way to have
        %weathervaning turbines.
    angles = zeros(NumTSs, 1); %FIXME will need to relate EWT.CurrentDirection to Turbines.o.
    speeds = EWT(el).CurrentSpeed(:, IterationNo);
    
    % We will calculate three sets of corrections: First, the exact
    % correction that we'd like to see on each timestep. Next, the Ctp
    % (Ct-prime) table that we'll put in place of the Ct table,
    % incorporating the mean value for CSA and modal number of layers; and
    % thirdly, a time-varying correction-to-the-correction that deals with
    % when these two diverge.
    % There will be a slight inaccuracy when the sea level or direction is
    % far from the mean; it also won't give the right answers if the
    % correction itself has a significant effect on the surface elevation
    % or current direction - in which case iteration will be needed.
    
    TSCts = Turbines(t).giCd(speeds, angles);
    DesiredCorrections = MTMC.fnCalcCorrections( angles, NumLayersIntersected, TSCts, EWT(el).CSA(:, IterationNo), Turbines(t).Diameter/2 );
    
    %now the table of Ctp values using mean and modal values for CSA and
    %numlayers.
    Turbines(t).giCtp = MTMC.fnCalcCtpTable( Turbines(t), mean(EWT(el).CSA(:, IterationNo)), mode(NumLayersIntersected), 1 );
    %FIXME arrive at good value for that last parameter. Maybe 1, maybe
    %(probably) higher.

    %Now, for each timestep, to calculate what the Ctp table will give and
    %produce the further correction (Alpha) to reach the value in DesiredCorrections.
    % These differences will be due to changes in surface elevation,
    % numlayers, or direction (hence CSA) during the run, and also due to
    % differences between the exact correction and MIKE's linear
    % interpolation of the Ctp table (especially near the cutoffs).
    
    TSCtps = Turbines(t).giCtp(speeds, angles);
    Turbines(t).Alpha(:,IterationNo) = DesiredCorrections ./ ( TSCtps ./ TSCts );
    Turbines(t).Alpha(isnan(Turbines(t).Alpha)) = 1;    % there may be a NaA in there if Ct was zero. Change it to a 1 so there's no further correction.  
    Turbines(t).Alpha = ones(size(Turbines(t).Alpha)); %TEMPORARY disable the second-order correction for now.
    
end


% for t = 1:NumTurbines % for each turbine
%     for ts = 1:NumTSs   %for each timestep (maybe can vectorise this?)
%         
%         elno = Turbines(t).ElementNo;
%         el = find([EWT.ElementNo]==elno);  
%         % find the angle between the current direction and the turbine
%         % orientation (anticlockwise, in radians)
%         %angle = EWT(el).CurrentDirection(ts,IterationNo) - Turbines(t).o;
%         %FIXME for now, assume weathervaning turbines always facing into
%         %flow. When this is fixed, still need to allow for a way to have
%         %weathervaning turbines.
%         angle = 0;  %TEMPORARY.
%         speed = EWT(el).CurrentSpeed(ts, IterationNo);
%         
%         Cd = Turbines(t).giCd(speed, angle); % this will interpolate from the values that we have
%         Cl = Turbines(t).giCl(speed, angle);
% 
%         Ae = pi * (Turbines(t).Diameter/2).^2 * cos(angle);   %effective area, viewed from current direction
%         
%         %find how many layers the rotor occupies
%         NumLayersIntersected = MTMC.fnFindLayersForTurbine(Turbines(t).z, Turbines(t).Diameter, EWT(el).SeabedElevation, NumLayers, EWT(el).DeltaZ(ts, IterationNo));
%         
%         % calculate nu, which is the proportion of the momentum passing
%         % through the turbine's element that is removed 
%         % FIXME WRONG IF MULTIPLE TURBINES IN CELL
%         %   FIXME also this currently ignores Cl.
%         nu = ( Cd * Ae / NumLayersIntersected ) / EWT(el).CSA(ts, IterationNo);
%         % calculate alpha, the correction value.
%         alpha = 4 / ( 1 + sqrt( 1 - nu ) ).^2;
%         Turbines(t).Alpha(ts, IterationNo) = alpha;
%         clear nu alpha Cd Cl Ae  angle speed el elno;
%         
%     end
% 
% end


%% Create dfs0 file with time-varient alpha values for each turbine
%      (One file with multiple items, item for each turbine)
disp('Writing dfs0 of time-varying correction factors...');  % create a new dfs0 of correction factors for each iteration. Seems safer that way.
[path, filename, ext] = fileparts(Alphadfs0Filename);
itFilename = [ path '\' filename '_it' num2str(IterationNo) ext ];  %this will probably break if it isn't on Windows. But so will anything that accesses dfs0s.
clear path filename ext;
MTMC.fnCreateAlphaDFS0( Turbines, itFilename, NumTSs, TSLength, StartTime, IterationNo );


%% Modify m3fm file to insert new Ct (Ctp) table and point at these dfs0 files
%for each turbine, create a new "CORRECTION_FACTOR" file section. Store
%these as columns of a cell array.
disp('Modifying m3fm file...');

caCFs = cell(11,NumTurbines);
caTables = cell( 6 + length(Turbines(1).giCtp.GridVectors{1}) * 2, NumTurbines);
%FIXME WARNING WARNING WARNING this will go wrong if different turbines
%have different lengths of Ctp tables!!! 
% Could probably find the turbine with the longest table and use that -
% don't think MIKE would mind blank lines, though would need to test. Or,
% could just make sure that all tables are the same length by expanding
% them to a fixed number of rows rather than a multiple of the original...

for t = 1:NumTurbines
    caCFs(:,t) = MTMC.fnCreateCFSection(itFilename, t);
    caTables(:,t) = MTMC.fnCreateCtpTableSection(Turbines(t).giCtp);
end

res = MTMC.fnReplaceM3FMSection(m3fmFilename, 'TABLE', caTables, 'multiple');
if res == -1
    error('Replacing the correction_factor sections failed.');
end
fprintf('Modified %i "TABLE" sections.\n', res);

res = MTMC.fnReplaceM3FMSection(m3fmFilename, 'CORRECTION_FACTOR', caCFs, 'multiple');
if res == -1
    error('Replacing the correction_factor sections failed.');
end
fprintf('Modified %i "CORRECTION_FACTOR" sections.\n', res);

clear caCFs caTables res t;

%% Write data file for next iteration

disp('Saving .mat state file for next iteration...');
save(matFilename, 'EWT', 'IterationNo', 'NumEWT', 'NumLayers', 'NumTSs', 'NumTurbines', 'StartTime', 'trMesh', 'trMesh2D', 'TSLength', 'Turbines');

end

