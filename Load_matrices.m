clear; clc; close all
% Specify the folder containing .mat files
myFolder = 'C:\Users\srtii\OneDrive\Chapter 3\Final_20250917\Assets and Liabilities\Full_Banks\data_spline';  % Change to your path
if ~isfolder(myFolder)
    error('Folder does not exist: %s', myFolder);
end

% Get list of all .mat files
filePattern = fullfile(myFolder, '*.mat');
matFiles = dir(filePattern);

fprintf('Found %d .mat files\n', length(matFiles));

% Load each file
for k = 1:length(matFiles)
    baseFileName = matFiles(k).name;
    fullFileName = fullfile(matFiles(k).folder, baseFileName);
    
    fprintf('Loading file %d of %d: %s\n', k, length(matFiles), baseFileName);
    
    % Load the file
    load(fullFileName);
    
    % Process your data here
    % Example: access variables from the loaded file
    % variableNames = fieldnames(data);
    % for i = 1:length(variableNames)
    %     eval([variableNames{i} ' = data.' variableNames{i} ';']);
    % end
    
    % Or store in cell array for later use
    % allData{k} = data;
    % fileNames{k} = baseFileName;
end
