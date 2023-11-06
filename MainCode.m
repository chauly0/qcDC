%% MainCode.m
% Chau Ly, Department of Bioengineering 
% Laboratory of Dr. Amy Rowat, University of California, Los Angeles 

% The general design of the code is further detailed in the publication
% referenced below: 
% Ly C, Ogana H, Kim HN, Hurwitz S, Deeds EJ, Kim YM, Rowat AC."Altered
% physical phenotypes of leukemia cells that survive chemotherapy
% treatment." Integrative Biology (2023). 

% Parts of code previously published in Dr. Amy Rowat's Lab including past
% work by Bino Varghese, David Hoelzle, Sam Bruce, Ajay Gopinath, Mike
% Scott, and Kendra Nyberg

close all
clear variables
clc

%% Initializations

numDataCols = 9;
writeData = [];
pairedWriteData = [];
pathSplit = [];
compData = [];
pairedData = [];

processedMulti = {'Diameter (um)', 'C1 Transit Time (ms)', 'C1 Entry Frame', 'C1 Exit Frame', 'Entry Occlusion', 'Exit Occlusion', 'Average Occlusion', 'Max Occlusion', 'Lane', 'VideoName','Experiment','Condition',...
    'C2 Time Interval (ms)', 'C3 Time Interval (ms)', 'C4 Time Interval (ms)', 'C5 Time Interval (ms)', 'C6 Time Interval (ms)', ...
    'C2 Exit Frame', 'C3 Exit Frame', 'C4 Exit Frame', 'C5 Exit Frame', 'C6 Exit Frame', ...
    'C1 Total Time', 'C2 Total Time', 'C3 Total Time', 'C4 Total Time', 'C5 Total Time', 'C6 Total Time', ...
    'Slope', 'Rsquared', 'Adjusted Rsquared'};


%% User input dialog box initiation
prompt = {sprintf('1. What type of particles are in your videos?\n(1=Cells, 2=Agrose Gels, 3=Oil Droplets, or 4=Monocytes)'),...
    '2. Do you want to check for correct mask fitting? (Y/N)', ...
    '3. Do you want to use user-defined detection filters? (Y/N)'};
dlg_title = 'User Preferences';
num_lines = 1;
def = {'4','N','N'};
userPref = inputdlg(prompt,dlg_title,num_lines,def); %newid is a function similar to inputdlg and requires download to the toolbox folder


%% Loads video files and prepare any metadata
[pathNames, videoNames] = PromptForVideos('G:\CellVideos\', '.avi');

% Checks to make sure at least one video was selected for processing
if(isempty(videoNames{1}))
    disp('No videos selected.');
    close all;
    return;
end

%% Extracts the template size and frame rates from the video name.
%   The video names should include, anywhere in the name, the following:
%   1) "devNx" where N is constriction width / template size to use
%       ex. "dev5x10"
%   2) "Mfps", where M is the frame rate in frames per second
%       ex. "1200fps"
% Example of properly formatted video names:
% 'dev5x10_1200fps_48hrppb_glass_4psi_20x_0.6ms_p12_041'

% Allocating matrices
templateSizes = ones(1, length(videoNames));
frameRates = ones(1, length(videoNames));

for i = 1:length(videoNames)
    videoName = videoNames{i};
    if regexp(videoName, 'dev\d*x')
        [j,k] = regexp(videoName, 'dev\d*x');
    elseif regexp(videoName, 'Dev\d*x')
        [j,k] = regexp(videoName, 'Dev\d*x'); % store start/end indices of template size
    else
        disp('File name error.');
        close all;
        return;
    end
    
    [m, n] = regexp(videoName, '\d*fps'); % store start/end indices of frame rate
    templateSize = videoName((j+3):(k-1)); % removes 'dev' at the start, and 'x' at the end
    frameRate = videoName(m:(n-3)); % removes 'fps'  at the end
    
    templateSizes(i) = str2double(templateSize);
    frameRates(i) = str2double(frameRate);
end


%% Loads filter preferences
% filters is a matrix of filter preferences per video each row corresponds
% to the following parameters:
% (1)sample bckgrnd window; (2)backgroundImg averaging pixel range; (3) threshold division--> the greater, the lower the threshold;
% (4)bwareaopen size range cutoff; (5) median filtering radius to remove excess
% noise (originally 5)

if strcmp(userPref(3),'Y') == 1
    disp('Searching for filters.xlsx in first data folder...');
    %Loads excel file for gel detection filter settings
    filters = xlsread([pathNames{1}, 'filters.xlsx']);
    
    % Checks to make sure the filters were located
    if(isempty(filters))
        disp('No filters found.');
        return;
    else
        disp('Filters found.');
    end
    
    % Checks to make sure the filters are the same length as the Video Names
    if(size(filters,2)~=size(videoNames,2))
        disp('The number of filters does not correspond with the number of videos.');
        return;
    end
    
    filters = filters(1:5,:);

elseif strcmp(userPref(1),'2') == 1
    filters = [500; 3; 30; 35; 5];
    filters = repmat(filters, 1, size(videoNames,2));
end


%% Checks for mask alignment
if strcmp(userPref(2),'Y') == 1
    disp('Warning: Videos will not be processed.')
    fprintf('\nAligning masks...\n')
    
    alignment = {'File Path', 'Video Name', 'Y Offset', 'Start Y Coordinate', 'End Y Coordinate'};
    
    for i = 1:length(videoNames)
        % Initializations
        currPathName = pathNames{i};
        currVideoName = videoNames{i};
        currVideo = VideoReader(fullfile(currPathName, currVideoName));
        
        % Calls the MakeWaypoints function to define the constriction region.
        % This function draws a template with a line across each constriction;
        % these lines are used in calculating the transit time
        [mask, lineTemplate, xOffset, yOffset, maskCheck] = MakeWaypoints(currVideo, templateSizes(i), userPref(2));
        
        if i==1
            maskChecks(:,:,:,i) = maskCheck;
        elseif isequal(size(maskCheck),size(maskChecks(:,:,:,1)))
            maskChecks(:,:,:,i) = maskCheck;
        else
            maskChecks(:,:,:,i) = zeros(size(maskChecks(:,:,:,1)));
        end
        
        startPos = 33 + yOffset;
        endPos = 65 + yOffset;
        
        alignment = vertcat(alignment, {currPathName, currVideoName, yOffset, startPos, endPos});
        
    end
    
   
    maskChecksMov = immovie(maskChecks);
    implay(maskChecksMov,4)
    set(findall(0, 'tag', 'spcui_scope_framework'), 'position', [500 300 600 400]);
    fprintf('Done.\n')
    return
end


%% Create the folder in which to store the output data
% The output folder name is a subfolder in the folder where the first videos
% were selected. The folder name contains the time at which processing is
% started.

% outputFolderName = fullfile(pathNames{1}, ['_MultiTT', videoName]);
% 
% if ~(exist(outputFolderName, 'file') == 7) % Checking if there's NOT already a folder, but the 'file' part of exist is weird. 
%     %The problem is that this will always make a folder. useless?
%     mkdir(outputFolderName);
% end

lastPathName = pathNames{i};


%% Initializes a progress bar
progressbar('Overall', 'Cell detection', 'Cell tracking');
tStart = tic;


%% Iterates through videos to filter, analyze, and output the compiled data
for i = 1:length(videoNames)
    % Initializations
    currPathName = pathNames{i};
    
    %outputFilename = fullfile(outputFolderName, regexprep(currPathName, '[^a-zA-Z_0-9-]', '~', 'all'));
    
    currVideoName = videoNames{i};
    currVideo = VideoReader(fullfile(currPathName, currVideoName));
    disp(['==Video ', num2str(i), '==']);
 
    startFrame = 1;
    endFrame = currVideo.NumberOfFrames;
    
    % Calls the MakeWaypoints function to define the constriction region.
    % This function draws a template with a line across each constriction;
    % these lines are used in calculating the transit time
    [mask, lineTemplate, xOffset] = MakeWaypoints(currVideo, templateSizes(i));

%% CellDetection    
    % Calls CellDetection to filter the images and store them in
    % 'processedFrames'.  These stored image are binary and should
    % (hopefully) only have the cells in them
    if strcmp(userPref(1),'1') == 1 % Videos containing cells
        [processedFrames, processedStart] = CellDetection(currVideo, startFrame, endFrame, currVideoName, mask);
     elseif strcmp(userPref(1),'2') == 1 % Videos containing gels
        [processedFrames] = GelDetection(currVideo, startFrame, endFrame, currVideoName, mask, filters);
    elseif strcmp(userPref(1),'3') == 1 % Videos containing oil droplets
        [processedFrames] = OilDetection(currVideo, startFrame, endFrame, currVideoName, mask);
    elseif strcmp(userPref(1),'4') == 1 % Newer Cell Detection code that started with the U937 monocytes
        [processedFrames] = MonocyteDetection(currVideo, startFrame, endFrame, xOffset, mask);
    elseif strcmp(userPref(1),'5') == 1 % Newer Cell Detection code to see if Vesicles Filtered Out?
        [processedFrames] = CellDetectionV29x10(currVideo, startFrame, endFrame, xOffset, mask);    
   end  
        
%% Calls CellTracking to track the detected cells.

%     % For the size gated compMulti32L
%     %ll lower limit
%     llSizeG = 12;
% 
%     %ul upper limit
%     ulSizeG = 16;


    [cellInfo, compMulti32L] = CellTracking(frameRates(i), lineTemplate, processedFrames, xOffset, currVideoName);
    progressbar((i/(size(videoNames,2))), 0, 0)


    
%% Formatting the data (compMulti32L into processedMulti)

    [vidMulti, pathSplit] = writeOutput(i, pathNames, pathSplit, videoNames, compMulti32L);
    processedMulti = vertcat(processedMulti, vidMulti);
    
   

    lastPathName = currPathName;
    

 end
 
%% Output as excel file 


outputFolderName = fullfile(pathSplit{1,1:end-1}, '_MultiV3');
 
% If there's NOT already an existing _MultiTT folder, make the folder
% 7 checks what kind of format is the path, specifically if its a folder
 if ~(exist(outputFolderName, 'file') == 7) 
     mkdir(outputFolderName);
 end

% Add unique timestamp to Excel filename (will be useful to enable PC to open multiple Excel files that don't have the same name)
% For more uniqueness, second number will be the hour of the day in military time
time = fix(clock);
timeStamp = num2str(time(1,1:3));
timeStamp = timeStamp(~isspace(timeStamp));

timeStampFull = strcat(timeStamp(3:end), '_', num2str(time(1,4)), '_', 'ProcessedMulti.xlsx');

pathProcessed = fullfile(outputFolderName, timeStampFull);
writecell(processedMulti, pathProcessed);



disp('Done!')
