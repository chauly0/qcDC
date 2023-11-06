%% CellDetection.m
% function [processed] = CellDetection(currVideo, startFrame, endFrame)
% CellDetection loads the videos selected earlier and processes each frame
% to isolate the cells.  When debugging, the processed frames can be
% written to a video, or the outlines of the detected cells can be overlaid
% on the video.

% Code from Dr. Amy Rowat's Lab, UCLA Department of Integrative Biology and
% Physiology
% Code originally by Bino Varghese (October 2011)
% Updated by David Hoelzle (January 2013)
% Updated by Mike Scott (July 2013)
% Rewritten by Ajay Gopinath (July 2013)
% Updated by Kendra Nyberg (May 2014)

% Inputs
%   - cellVideo: a videoReader object specifying a video to load
%   - startFrame: an integer specifying the frame to start analysis at
%   - endFrame: an integer specifying the frame to end analysis at
%   - folderName: a string specifying the filepath
%   - currVideoName: a string specifying the video's name
%   - mask: a logical array that was loaded in makeWaypoints and is used to
%       erase objects found outside of the lanes of the cell deformer.

% Outputs
%   - processed: An array of dimensions (height x width x frames) that
%       stores the processed frames.  Is of binary type.

% Changes
% Automation and efficiency changes made 03/11/2013 by Dave Hoelzle
% Commenting and minor edits on 6/25/13 by Mike Scott
% Increase in speed (~3 - 4x faster) + removed disk output unless debugging made on 7/5/13 by Ajay G.

function [processed] = MonocyteDetection(currVideo, startFrame, endFrame, xOffset, consMask)
%%% This code analyzes a video of cells passing through constrictions
%%% to produce and return a binary array of the video's frames which
%%% have been processed to yield only the cells.

progressbar([],0,[])

DEBUG_FLAG = false; % flag for whether to show debug info
WRITEMOVIE_FLAG = false; % flag whether to write processed frames to a movie file


%% Initialization for debugging
% folderName = 'Y:\Kendra\qDC Experiments\170405 - Human Monocytes with ISO treatment\Control\';
% %folderName = '/Volumes/Rowat Lab Data 2/Kendra/Lowry Lab Collaboration/131219 - HSF1 and HSF1 NPC Repeats/HSF1/';
% currVideoName = 'dev3x5_200fps_10psi_20x_004.cine';
% userPref = {'N','N','N', '1', 'N', '1'};
% 
% % Grabs video specs
% currVideo = CineReaderRaw(fullfile(folderName, currVideoName));
% % startFrame = 1;
% startFrame = 1;
% endFrame = currVideo.NumberOfFrames;
% 
% % Determines mask variable
% [j,k] = regexp(currVideoName, 'dev\d*x'); % store start/end indices of template size
% templateSize = currVideoName((j+3):(k-1)); % removes 'dev' at the start, and 'x' at the end
% [mask, ~, ~] = MakeWaypoints(currVideo, templateSize, 1);

% Determines framerate
% frameRate = currVideo.FrameRate; % removes 'fps'  at the end

%% Initialize variables
% stores the number of frames that will be processed
effectiveFrameCount = (endFrame-startFrame+1) ;
height = currVideo.height;
width = currVideo.width;



%% Builds a background frame
bgImg = double(read(currVideo, startFrame));

% takes 10 equally spaced frames to compare the initial frame to
bgFrames = zeros(size(bgImg));
for bgIndx = 1:10
    bgFrames = bgFrames + double(read(currVideo, floor((endFrame-startFrame)*bgIndx/10)+1));
end
bgFrames = bgFrames/10;

% corrects the bgframe by removing the unique objects
bgImg(bgFrames - bgImg > 5 | bgFrames - bgImg < -5) = bgFrames(bgFrames - bgImg > 5 | bgFrames - bgImg < -5);

%% Create constriction mask to clean up transit frames
laneCoords = [16 48 81 113 146 178 210 243 276 308 341 373 406 438 471 503] + xOffset;
if ismac
    consMask = mat2gray(bgImg, [-50 50]);
    consMask = ~im2bw(consMask, graythresh(consMask));
    consMask = ~imfill(consMask, [10*ones(1, 16); laneCoords]');
    consMask = imfill(consMask, 'holes');
    consMask = imdilate(consMask, strel('disk', 1));
    consMask = ~logical(consMask);
end

%% Prepare for Cell Detection
% create structuring elements used in cleanup of grayscale image
forClose = strel('disk', 5);

% automatic calculation of threshold value for conversion from grayscale to binary image
currImg = mat2gray(double(read(currVideo, startFrame))-bgImg, [-50 50]);
threshold = graythresh(currImg);
if threshold < 0.5
    threshold = threshold*2;
end

% preallocate memory for marix for speed
processed = false(height, width, effectiveFrameCount);
startTime = tic;

% Step through video
% iterates through each video frame in the range [startFrame, endFrame]
for frameIdx = startFrame:endFrame
        
    % Reads movie frame at frameIdx
    currFrame = read(currVideo, frameIdx);
    
    % Background subtraction
    cleanImg = double(currFrame)-bgImg;
    
    % Mask removal
    cleanImg = im2bw(-cleanImg, threshold);
    cleanImg = bwareaopen(cleanImg, 50, 4);
    
    cleanImg = imclose(cleanImg, forClose); %connects gaps

    cleanImg(~consMask) = 0;
    cleanImg = imfill(cleanImg, 'holes');
    
    %% Black and white
%     figure(2); imshow([currFrame cleanImg*255])
%     
    %%
    % Store cleaned image of segmented cells in processed
    processed(:,:,frameIdx-startFrame+1) = cleanImg;
 
    % Increments the progress bar, each time 1% of the frames are finished
    if mod(frameIdx, floor(effectiveFrameCount/100)) == 0
        progressbar([], frameIdx/effectiveFrameCount, [])
    end
end

% stop recording the time and output debugging information
totalTime = toc(startTime);
disp(['Time taken for cell detection: ', num2str(totalTime), ' secs']);
disp(['Average time to detect cells per frame: ', num2str(totalTime/effectiveFrameCount), ' secs']);

%% Set up frame viewer and write to file if debugging is on
if(DEBUG_FLAG)
    implay(processed);
    
    % if video file is set
    if(WRITEMOVIE_FLAG)
        writer = VideoWriter([folderName, 'cellsdetected_', videoName]);
        open(writer);
        
        if(islogical(processed))
            processed = uint8(processed); % convert to uint8 for use with writeVideo

            % make binary '1's into '255's so all resulting pixels will be
            % either black or white
            for idx = 1:effectiveFrameCount
                processed(:,:,idx) = processed(:,:,idx)*255;
            end
        end
        
        % write processed frames to disk
        for currFrame = startFrame:endFrame
            writeVideo(writer, processed(:,:,currFrame-startFrame+1));
        end
        
        close(writer);
    end
end