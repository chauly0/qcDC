% Code from Dr. Amy Rowat's Lab, UCLA Department of Integrative Biology and
% Physiology

% Code by Chau Ly (October 2021)

function [vidMulti, pathSplit] = writeOutput(i, pathNames, pathSplit, videoNames, compMulti32L)


vidMulti = cell(size(compMulti32L{1,1},1),31);
pathNumSlash = zeros(size(pathNames));

%% Grab sample names and experiment name

%If its the first video and pathSplit has not been loaded yet 
if (isempty(pathSplit))
    
%Loop through all of pathNames to obtain NUMBER of how many there are
%of "\" and save 
    for ii = 1:size(pathNames,2)
        pathNumSlash(ii)= size(strfind(pathNames{ii},'\'),2);
    end    
pathSplit = cell(0,max(pathNumSlash));


% Loop through all directory paths in array and load partitions into pathSplit 

    for ii = 1:size(pathNames,2)
        pathName = pathNames{ii};
        dirSplit = strsplit(pathName(1:size(pathName,2)-1),'\\'); %works with one "\" ?
        pathSplit(ii,1:size(dirSplit,2)) = dirSplit;
    end
end    
%     samp = dirSplit(end);
%     exptName = dirSplit(end-1);

%     dirSplit = pathSplit(i,:);

%% Data Cleaning
% Last round of data cleaning 
% Previous data cleaning was done in ProcessTrackingData

% Only include cell data of cells with all positive transit time intervals





%% Write most useful features into output

% Cell Diameter (um)
%To Do - for consistency, check if previous diameter came from line 1 or 2
vidMulti(:,1) = num2cell(compMulti32L{1,4}(:,1));

% C1 Transit Time 
vidMulti(:,2) = num2cell(compMulti32L{1,2}(:,7));

% C1 Entry Frame 
% To Do - for consistency, check if came from line 1 or 2 
vidMulti(:,3) = num2cell(compMulti32L{1,1}(:,1));

% C1 Exit Frame 
% WRITTEN FOR BOTTOM OF CONSTRICTION BULB
vidMulti(:,4) = num2cell(compMulti32L{1,1}(:,7));

% Entry Occlusion
% To Do - Include/exclude occlusions? Old Transit Time Code had lots of
% inaccurate occlusion counts that was unreliable
vidMulti(:,5) = num2cell(zeros(size(compMulti32L{1,1},1),1));

% Exit Occlusion
vidMulti(:,6) = num2cell(zeros(size(compMulti32L{1,1},1),1));

% Average Occlusion 
vidMulti(:,7) = num2cell(zeros(size(compMulti32L{1,1},1),1));

% Max Occlusion
vidMulti(:,8) = num2cell(zeros(size(compMulti32L{1,1},1),1));

% Lane
vidMulti(:,9) = num2cell(compMulti32L{1,10}(:,1));

% VideoName
vidMulti(:,10) = cellstr(repmat(compMulti32L{2,11}, size(compMulti32L{1,1},1) ,1));

% Experiment 
vidMulti(:,11) = cellstr(repmat(pathSplit(i,end-1), size(compMulti32L{1,1},1) ,1));

% Condition 
vidMulti(:,12) = cellstr(repmat(pathSplit(i,end), size(compMulti32L{1,1},1) ,1));

% % % % % %

% C2 Time Interval (ms)
vidMulti(:,13) = num2cell(compMulti32L{1,2}(:,11)-compMulti32L{1,2}(:,7));

% C3 Time Interval (ms)
vidMulti(:,14) = num2cell(compMulti32L{1,2}(:,15)-compMulti32L{1,2}(:,11));

% C4 Time Interval (ms)
vidMulti(:,15) = num2cell(compMulti32L{1,2}(:,19)-compMulti32L{1,2}(:,15));

% C5 Time Interval (ms)
vidMulti(:,16) = num2cell(compMulti32L{1,2}(:,23)-compMulti32L{1,2}(:,19));

% C6 Time Interval (ms)
vidMulti(:,17) = num2cell(compMulti32L{1,2}(:,27)-compMulti32L{1,2}(:,23));

%% % % % % %

% C2 Exit Frame
vidMulti(:,18) = num2cell(compMulti32L{1,1}(:,11));

% C3 Exit Frame
vidMulti(:,19) = num2cell(compMulti32L{1,1}(:,15));

% C4 Exit Frame
vidMulti(:,20) = num2cell(compMulti32L{1,1}(:,19));

% C5 Exit Frame
vidMulti(:,21) = num2cell(compMulti32L{1,1}(:,23));

% C6 Exit Frame
vidMulti(:,22) = num2cell(compMulti32L{1,1}(:,27));

% Total Time 
% C1 Transit Time 
% WRITTEN FOR BOTTOM OF CONSTRICTION BULB
vidMulti(:,23) = num2cell(compMulti32L{1,2}(:,7));

% C2 Total Time 
vidMulti(:,24) = num2cell(compMulti32L{1,2}(:,11));

% C3 Total Time 
vidMulti(:,25) = num2cell(compMulti32L{1,2}(:,15));

% C4 Total Time 
vidMulti(:,26) = num2cell(compMulti32L{1,2}(:,19));

% C5 Total Time 
vidMulti(:,27) = num2cell(compMulti32L{1,2}(:,23));

% C6 Total Time 
vidMulti(:,28) = num2cell(compMulti32L{1,2}(:,27));


%% Do 7-point (including 0,0) linear regression
% For constrictions 1-6

for iSampCell = 1:size(vidMulti,1)
    
absTime = horzcat(0, cell2mat(vidMulti(iSampCell,23:28)))'; % Load total time to get through each of the 6 constrictions  
absDistance = horzcat(0, 51.72:34.48:224.1200)'; % Exact micrometer measurements along length of 5x5 q-DC device (corresponding to the 6 constrictions)



tbl = table(absTime, absDistance);
lm = fitlm(tbl,'linear');

%% For demonstration
% figure(1)
% plot(lm, 'LineWidth', 5, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD')
% hold on
% ylabel('Distance (μm)')
% xlabel('Total Time (ms)')
% hold off


%% For demo - change colors from fitlm 
% figure(1)
% h = plot(lm, 'LineWidth', 5, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD');

% hold on


% % Get handles to plot components
% dataHandle = findobj(h,'DisplayName','Data');
% fitHandle = findobj(h,'DisplayName','Fit');
% % The confidence bounds have 2 handles but only one of 
% % the handles contains the legend string.  The first
% % line below finds that object and then searches for 
% % other objects in the plot that have the same linestyle
% % and color. 
% cbHandles = findobj(h,'DisplayName','Confidence bounds');
% cbHandles = findobj(h,'LineStyle',cbHandles.LineStyle, 'Color', cbHandles.Color);
% %cbHandles = findobj(h,'LineStyle','-', 'Color', cbHandles.Color);
% 
% %cbHandles.Color = '#0072BD'; 
% dataHandle.Color = '#5cabf5'; 
% fitHandle.Color = '#0078ff'; 
% set(cbHandles, 'Color', '#0078ff', 'LineWidth', 1)
% set(fitHandle, 'LineWidth', 2)
% set(dataHandle, 'Marker', '+')
% 
% ylabel('Distance (μm)')
% xlabel('Total Time (ms)')
% hold off

%% Grab slope
vidMulti(iSampCell,29) = table2cell(lm.Coefficients(2,1));

% Grab R-squared
vidMulti(iSampCell,30) = num2cell(lm.Rsquared.Ordinary);

% Grab Adjusted R-squared
vidMulti(iSampCell,31) = num2cell(lm.Rsquared.Adjusted);

% Grab Pearson residuals 
%vidMulti(iSampCell,32:37) = num2cell(lm.Residuals.Pearson');
end 

%% Complete linear regression of constriction 1 only
% 
% for iSampCell = 1:size(compMulti32L{1,1},1)
% absTime  = compMulti32L{1,2}(iSampCell,1:7)'; % Load total time to get through 1st constriction


%Linear regression
% tbl = table(absTime, [1:7]');
% lm = fitlm(tbl,'linear');
% 
% figure(1)
% plot(lm, 'LineWidth', 5, 'MarkerFaceColor', '#0072BD', 'Color', '#0072BD')
% hold on
% ylabel('Horizontal line')
% xlabel('Total Time (ms)')
% hold off

%Plots only, no fitting
% figure(1)
% scatter(absTime,[1:7])
% hold on
% ylabel('Horizontal line')
% xlabel('Total Time (ms)')
% hold off

end