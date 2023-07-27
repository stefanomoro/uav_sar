mainFolder = "E:\data-stefano\test";
for ii = 2:2
experimentName = ['exp',num2str(ii)];

folderName = fullfile(mainFolder, experimentName);

if exist(folderName,"dir")
    error("Folder already present");
end

mkdir(folderName);

mkdir(fullfile(folderName, "raw"));
mkdir(fullfile(folderName, "rc"));
mkdir(fullfile(folderName, "images"));
mkdir(fullfile(folderName, "trajectories"));
mkdir(fullfile(folderName, "waveform"));

end