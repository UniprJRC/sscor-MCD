function analyzeProjectDependencies(projectFolder)
    % ANALYZEPROJECTDEPENDENCIES Analyzes all .m and .mlx files in a folder for dependencies
    % Specifically identifies dependencies linked to the FSDA toolbox
    %
    % Input:
    %   projectFolder - Path to the folder containing MATLAB files to analyze
    
    %{
        analyzeProjectDependencies('../');    
    %}

    % Check if input folder exists
    if ~exist(projectFolder, 'dir')
        error('The specified folder does not exist: %s', projectFolder);
    end
    
    % Get all .m and .mlx files in the folder and subfolders
    mFiles = dir(fullfile(projectFolder, '**/*.m'));
    mlxFiles = dir(fullfile(projectFolder, '**/*.mlx'));
    allFiles = [mFiles; mlxFiles];
    
    % Initialize results structure
    results = struct('Filename', {}, 'Path', {}, 'Dependencies', {}, 'FSDADependencies', {});
    
    % Get FSDA toolbox path and functions
    fsdaPath = getFSDAPath();
    fsdaFunctions = {};
    
    if ~isempty(fsdaPath)
        % Get all FSDA functions
        fsdaFiles = dir(fullfile(fsdaPath, '**/*.m'));
        fsdaFunctions = cellfun(@(x) x(1:end-2), {fsdaFiles.name}, 'UniformOutput', false);
    end
    
    % Process each file
    fprintf('Analyzing %d files for dependencies...\n', length(allFiles));
    
    for i = 1:length(allFiles)
        currentFile = allFiles(i);
        filePath = fullfile(currentFile.folder, currentFile.name);
        [~, fileName, ~] = fileparts(currentFile.name);
        
        fprintf('Processing file %d/%d: %s\n', i, length(allFiles), currentFile.name);
        
        try
            % Get dependencies using MATLAB's built-in function
            deps = matlab.codetools.requiredFilesAndProducts(filePath, 'topOnly');
            
            % Filter out standard MATLAB functions and get only the file names without path
            depNames = cell(size(deps));
            for j = 1:length(deps)
                [~, depName, ~] = fileparts(deps{j});
                depNames{j} = depName;
            end
            
            % Find FSDA dependencies
            if ~isempty(fsdaFunctions)
                fsdaDeps = intersect(depNames, fsdaFunctions);
            else
                % If FSDA path not found, try to identify by name pattern
                fsdaDeps = depNames(startsWith(depNames, 'FSDA_') | ...
                                   startsWith(depNames, 'fsda_'));
            end
            
            % Add to results
            results(i).Filename = fileName;
            results(i).Path = filePath;
            results(i).Dependencies = depNames;
            results(i).FSDADependencies = fsdaDeps;
        catch e
            warning('Error analyzing %s: %s', filePath, e.message);
            
            % Still add to results, but mark as error
            results(i).Filename = fileName;
            results(i).Path = filePath;
            results(i).Dependencies = {'ERROR_ANALYZING_FILE'};
            results(i).FSDADependencies = {};
        end
    end
    
    % Save results
    resultsTable = struct2table(results);
    
    % Display summary
    fprintf('\n===== DEPENDENCY ANALYSIS SUMMARY =====\n');
    fprintf('Total files analyzed: %d\n', height(resultsTable));
    
    % Count files with FSDA dependencies
    filesWithFSDAdeps = sum(cellfun(@(x) ~isempty(x), resultsTable.FSDADependencies));
    fprintf('Files with FSDA dependencies: %d\n', filesWithFSDAdeps);
    
    % Display files with FSDA dependencies
    if filesWithFSDAdeps > 0
        fprintf('\nFiles with FSDA dependencies:\n');
        for i = 1:height(resultsTable)
            if ~isempty(resultsTable.FSDADependencies{i})
                fprintf('- %s: %s\n', resultsTable.Filename{i}, ...
                    strjoin(resultsTable.FSDADependencies{i}, ', '));
            end
        end
    end
    
    % Save to Excel
    outputFile = fullfile(projectFolder, 'dependency_analysis.xlsx');
    writetable(resultsTable, outputFile);
    fprintf('\nDetailed results saved to: %s\n', outputFile);
    
    % Return results
    assignin('base', 'dependencyResults', resultsTable);
    fprintf('\nResults also available in workspace variable "dependencyResults"\n');
end

function fsdaPath = getFSDAPath()
    % Try to find FSDA toolbox path
    
    % Method 1: Check if FSDA is in the path
    fsdaPath = '';
    allPaths = strsplit(path, pathsep);
    
    for i = 1:length(allPaths)
        if contains(lower(allPaths{i}), 'fsda')
            fsdaPath = allPaths{i};
            fprintf('FSDA toolbox found at: %s\n', fsdaPath);
            return;
        end
    end
    
    % Method 2: Try to find it using which
    try
        % Try to locate a known FSDA function
        knownFSDAFunc = which('FSM');
        if ~isempty(knownFSDAFunc)
            [fsdaPath, ~, ~] = fileparts(fileparts(knownFSDAFunc));
            fprintf('FSDA toolbox found at: %s\n', fsdaPath);
            return;
        end
    catch
        % Continue to next method
    end
    
    % Method 3: Ask user
    fprintf('FSDA toolbox not found automatically.\n');
    userInput = input('Do you want to specify the FSDA toolbox path? (y/n): ', 's');
    
    if lower(userInput) == 'y'
        fsdaPath = uigetdir('', 'Select FSDA toolbox folder');
        if fsdaPath == 0 % User canceled
            fsdaPath = '';
        end
    end
    
    if isempty(fsdaPath)
        warning('FSDA toolbox path not found. Will identify FSDA functions by name pattern only.');
    end
end
