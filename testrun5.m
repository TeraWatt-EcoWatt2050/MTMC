% script to test by running MTMC on five different models.

testpath = 'F:\MTMC stuff\not-in-git\test models\160317 new tri mesh';
sizes = [50 100 150 200 250];


for i = 1:length(sizes)
    m3fmfilename = sprintf('meshing%i.m3fm', sizes(i));
    m3fmfullfile = fullfile(testpath, m3fmfilename);
    meshfilename = sprintf('new tri mesh %im.mesh', sizes(i));
    meshfullfile = fullfile(testpath, meshfilename);
    matfilename = sprintf('working_%im.mat', sizes(i));
    matfullfile = fullfile(testpath, matfilename);
    resultsfolder = sprintf('meshing%i.m3fm - Result Files', sizes(i));
    turbinedfs0fullfile = fullfile(testpath, 'uncorrected', resultsfolder, 'turbine_data.dfs0');
    alphafilename = sprintf('alpha%i.dfs0', sizes(i));
    alphafullfile = fullfile(testpath, alphafilename);
    
    MTMC.MakeCorrection( m3fmfullfile, matfullfile, {turbinedfs0fullfile}, meshfullfile, alphafullfile)
end