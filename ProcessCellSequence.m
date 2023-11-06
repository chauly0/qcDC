%% ProcessCellSequence.m

%New ProcessCellSequence algorithm is based on finding the majority of the sequence
%Designed for cases where a cell has almost all the frames captured from
%horizontal line 1-27, but perhaps  missing a frame captured at one of the
%lines. As a result, this cell would be excluded from the output using the previous ProcessTrackingData
%algorithm that operates using +1 iteration on contactCount
%example a cell with horizontal lines 1-4 and 6-27, but missing line 5

%This algorithm relies on finding cells at the regions of the videos where the
%CellDetection is the best at image segmentation - at lines where the
%cells are most relaxed: line 7, 11, 15, 19, 23, 27. It works by calling
%logicals to the presence of a cell in the frames and finding a diagonal,
%which confirms the presence of a cell that traverses through the entire 6
%constrictions. 
%The benefit of this new algorithm, that avoids dependence on the +1 iterations of contactCount, 
%is that there are more cells captured and outputted into the data


% Code from Dr. Amy Rowat's Lab, UCLA Department of Integrative Biology and Physiology
% This script is originally by Chau Ly (November 2021)

% Room for code improvement if desiring more:
% (1) Combine stairs1-7 into a single cell array and step1-7 into a single vector
% (2) Combine the section for midstep and endstep 
% (3) Reduce different arrays holding laneData/trackingData/unpairedData
% (4) Detecting duplicate cells with similar frames - see Rep 1 - LAX7R vid06


% *** First big FOR loop
% Loop through each lane and connect a sequence of cell sightings based on the algorithm of 
% looking for cells at lines [1 2 3], 7, 11, 15, 19, 23, 27

% *** Second big FOR loop
% This loop is nested under the first big FOR loop as it goes through each
% lane
% Of the cells confirmed with the sequence, fill in the remainder of the
% lines to complete information for lines 1-27

% *** Third big FOR loop
% Transfer information and features about the cells into laneData,
% trackingData, etc. 


function [cellInfo, compMulti32L] = ProcessCellSequence(framerate, cellInfo, currVideoName)


% INITIALIZE
debuglaneData = cell(1, 32);
% laneData = zeros(2000,17,4);


% trackingData is a cell that contains the lane data for each lane
trackingData = cell(1,16);
occlStart = [];

%All cells confirmed must have reported horizontal lines 1, 2, and 3 in
%consecutive order. Note alternatives to be included potentially below 
startLines1 = [1 2 3];
%startLines2 = [1 3 4];
%startLines3 = [1 2 4];

%% 1ST BIG FOR LOOP - LOOP THROUGH EACH LANE
% Goes through the data for each lane (1-16)
for lane = 1:16 

    
cellInfoLane = cellInfo{1,lane}(:,3);
iStartLines = strfind(cellInfoLane', startLines1);

laneData = zeros(30,33,10); %MULTI - KEY NUMBER, may need to be changed. this 
% affects if Matlab will let you view laneData (524,588 elements)


            %when starting down to declare the diagonal, algorithm is
            %designed to start with column 1 of logisHorzLines (alternative
            %considered column 2, or horizontal line 7)
            
            logisHorzLines = zeros(size(cellInfoLane,1),7);
            
            %first column marked only if consecutive 1 2 3 sequence
            logisHorzLines(iStartLines,1) = 1; 
            
            logisHorzLines(:,2) = cellInfoLane==7;
            logisHorzLines(:,3) = cellInfoLane==11;
            logisHorzLines(:,4) = cellInfoLane==15;
            logisHorzLines(:,5) = cellInfoLane==19;
            logisHorzLines(:,6) = cellInfoLane==23;
            logisHorzLines(:,7) = cellInfoLane==27;
            
            
            stairs1 = find(logisHorzLines(:,1));
            stairs2 = find(logisHorzLines(:,2));
            stairs3 = find(logisHorzLines(:,3));
            stairs4 = find(logisHorzLines(:,4));
            stairs5 = find(logisHorzLines(:,5));
            stairs6 = find(logisHorzLines(:,6));
            stairs7 = find(logisHorzLines(:,7));
            
            iCellConfirmed = zeros(size(stairs1,1),7);
            

            %% Go through steps to find diagonal (aka a cell)
            
            for iCellPotential = 1:size(stairs1,1)
            
                % Indexed cell in stairs1 needs to not be the last cell in
                % order to be compared to see if the next cell has a larger
                if iCellPotential < size(stairs1,1)
                    
                % Is it able to walk over to second step
                % Must keep single amperand, can't short circuit because not scalar
                if find(stairs2 > stairs1(iCellPotential) & stairs2 < stairs1(iCellPotential+1))
%                     disp('First step was')
                    step1 = stairs1(iCellPotential);
                    iCellConfirmed(iCellPotential, 1) = step1; 
                    
%                     disp('Second step was')
                    step2 = stairs2(find(stairs2 > stairs1(iCellPotential) & stairs2 < stairs1(iCellPotential+1),1));
                    iCellConfirmed(iCellPotential, 2) = step2; 
                    
                    % Is it able to walk over to third step  
                    if find(stairs3 > step2)
                    % don't need this reference of the next iteration of step2 in stairs2? this one, stairs2(find(stairs2 == step2)+1)
%                     disp('Third step was')
                    step3 = stairs3(find(stairs3 > step2,1)); %NOTE There's several stair options and we're REPORTING THE FIRST VIABLE OPTION                     
                    iCellConfirmed(iCellPotential, 3) = step3; 
                    
                        % Is it able to walk over to fourth step 
                        if find(stairs4 > step3)
%                         disp('Fourth step was')
                        step4 = stairs4(find(stairs4 > step3,1));
                        iCellConfirmed(iCellPotential, 4) = step4; 
                        
                            % Is it able to walk over to fifth step 
                            if find(stairs5 > step4)
%                             disp('Fifth step was')
                            step5 = stairs5(find(stairs5 > step4,1));
                            iCellConfirmed(iCellPotential, 5) = step5; 
                            
                                % Is it able to walk over to sixth step 
                                if find(stairs6 > step5)
%                                 disp('Sixth step was')
                                step6 = stairs6(find(stairs6 > step5,1));
                                iCellConfirmed(iCellPotential, 6) = step6; 
                                
                                     % Is it able to walk over to seventh step 
                                     if find(stairs7 > step6)
%                                      disp('Seventh step was')
                                     step7 = stairs7(find(stairs7 > step6,1));
                                     iCellConfirmed(iCellPotential, 7) = step7;  
                                     else
%                                      disp('Failed to reach seventh step')
                                     end
                                else
%                                 disp('Failed to reach sixth step')
                                end 
                            else
%                             disp('Failed to reach fifth step')
                            end   
                        else
%                         disp('Failed to reach fourth step')
                        end
                    else 
%                     disp('Failed to reach third step')
                    end            
                else 
%                 disp('Failed to reach second step')   
                end 
                
                %%
                 else %iCellPotential is on the last cell from the first column of logisHorzLines aka stairs1
                     
                 % Is it able to walk over to second step
                if find(stairs2 > stairs1(iCellPotential),1)
%                     disp('First step was')
                    step1 = stairs1(iCellPotential);
                    iCellConfirmed(iCellPotential, 1) = step1; 
%                     disp('Second step was')
                    step2 = stairs2(find(stairs2 > stairs1(iCellPotential),1));
                    iCellConfirmed(iCellPotential, 2) = step2; 

                    % Is it able to walk over to third step  
                    if find(stairs3 > step2)
                    % don't need this reference of the next iteration of step2 in stairs2? this one, stairs2(find(stairs2 == step2)+1)
%                     disp('Third step was')
                    step3 = stairs3(find(stairs3 > step2,1)); %NOTE There's several stair options and we're REPORTING THE FIRST VIABLE OPTION                     
                    iCellConfirmed(iCellPotential, 3) = step3; 
                    
                        % Is it able to walk over to fourth step 
                        if find(stairs4 > step3)
%                         disp('Fourth step was')
                        step4 = stairs4(find(stairs4 > step3,1));
                        iCellConfirmed(iCellPotential, 4) = step4; 
                        
                            % Is it able to walk over to fifth step 
                            if find(stairs5 > step4)
%                             disp('Fifth step was')
                            step5 = stairs5(find(stairs5 > step4,1));
                            iCellConfirmed(iCellPotential, 5) = step5; 
                            
                                % Is it able to walk over to sixth step 
                                if find(stairs6 > step5)
%                                 disp('Sixth step was')
                                step6 = stairs6(find(stairs6 > step5,1));
                                iCellConfirmed(iCellPotential, 6) = step6; 
                                
                                     % Is it able to walk over to seventh step 
                                     if find(stairs7 > step6)
%                                      disp('Seventh step was')
                                     step7 = stairs7(find(stairs7 > step6,1));
                                     iCellConfirmed(iCellPotential, 7) = step7;     
                                     else
%                                      disp('Failed to reach seventh step') 
                                     end
                                else
%                                 disp('Failed to reach sixth step')
                                end 
                            else
%                             disp('Failed to reach fifth step')
                            end    
                        else
%                         disp('Failed to reach fourth step') 
                        end
                    else 
%                     disp('Failed to reach third step')
                    end      
                else 
%                 disp('Failed to reach second step')
                end    
                end                 
            end
            
% At this point, iCellConfirmed should be completed in lane #, with confirmed cells that have a
% diagonal aka they have a frame reported at the most essential horizontal lines of 1,
% 2, 3, 7, 11, 15, 19, 23, and 27


%% Take the confirmed cells from iCellConfirmed and fill in the full sequence from horizontal lines 1-27

% Note that iCellConfirmed only has the sequence of a cell at horizontal
% lines 1, 2, 3, 7, 11, 15, 19, 23, and 27, but we need to fill in the
% remainder

% Need to clean iCellConfirmed to ensure zeroes are not counted

iCellConfirmedClean = zeros(size(iCellConfirmed(all(iCellConfirmed,2),:),1),7);
iCellConfirmedClean = iCellConfirmed(all(iCellConfirmed,2),:);

% Need to check if ther are duplicates and exclude cell
%unique(iCellConfirmedClean, 'rows')

% Make expanded verion of iCellConfirmedClean to include remainder horizontal lines
iCellExpand = zeros(size(iCellConfirmedClean,1),27);

% Tranfer indexes from iCellConfirmedClean
iCellExpand(:,1) = iCellConfirmedClean(:,1);
iCellExpand(:,2) = iCellConfirmedClean(:,1)+1; %Because we know [1 2 3] was consecutive
iCellExpand(:,3) = iCellConfirmedClean(:,1)+2; %Because we know [1 2 3] was consecutive

iCellExpand(:,7) = iCellConfirmedClean(:,2);
iCellExpand(:,11) = iCellConfirmedClean(:,3);
iCellExpand(:,15) = iCellConfirmedClean(:,4);
iCellExpand(:,19) = iCellConfirmedClean(:,5);
iCellExpand(:,23) = iCellConfirmedClean(:,6);
iCellExpand(:,27) = iCellConfirmedClean(:,7);

%After transferring indices into iCellConfirmedExpand, there should be 5
%holes containing triplicates of indices to be found:
% - horizontal lines 4-6
% - horizontal lines 8-10
% - horizontal lines 12-14
% - horizontal lines 16-18
% - horizontal lines 20-22
% - horizontal lines 24-26


% SECOND BIG FOR LOOP - LOOP THROUGH EACH CELL WITHIN CURRENT LANE
% Complete the full sequence of lines 1-27 with correctly referenced
% indices
    for iSeq = 1:size(iCellExpand,1)



%% %%For lines that are the beginning of the holes (4, 8, 12, 16, 20, 24), 
       %the first number we look up in the sequence will automatically be
       %higher than it's previous. 
       %Because of the required lines of [1 2 3] needing to be a real integer, there will never be a situation 
       %in which the previous line is NaN
       
       beginHole = 4:4:24;
       for iBHole = 1:6
       currLine = beginHole(iBHole);
       potentBegin = find(cellInfoLane([iCellExpand(iSeq,currLine-1):iCellExpand(iSeq,currLine+3)])==currLine);
       potentBegin = potentBegin-1+iCellExpand(iSeq,currLine-1); %adjust index to full array cellInfo numbering
           
           if size(potentBegin,1) == 0 %If there's not a reported frame at this particular horizontal line
               iCellExpand(iSeq,currLine) = NaN; 
           else %If there's 1 or  more several frames/duplicates reported at this particular line
               iCellExpand(iSeq,currLine) = potentBegin(1); 
           end
       end
       

       
       %% For lines that are the middle of the holes (5, 9, 13, 17, 21, 25), 
       %Additional situation added - we need to account for if the index is lower than the previous beginHole lines 
       %In the case the beginHole line resulted in a Not a Number, then below is addressed due to MATLAB handling this situation differently
        

       midHole = 5:4:25;
       for iMHole = 1:6
       currLine = midHole(iMHole);
       potentMid = find(cellInfoLane([iCellExpand(iSeq,currLine-2):iCellExpand(iSeq,currLine+2)])==currLine);
       potentMid = potentMid-1+iCellExpand(iSeq,currLine-2); %adjust index to full array lubcellInfo numbering, will only work if its a real integer
   
       
           %If current line contains real integers & if previous line
           %contains real integers
           if isfinite(potentMid) & isfinite(iCellExpand(iSeq,currLine-1))
               potentMid(:,2) = potentMid(:,1) >= iCellExpand(iSeq,currLine-1); %Logicals - Ask which line is larger than previous
               try %If current line/line duplicates have a line that's larger than previous, then report into iCellExpand
                   iCellExpand(iSeq,currLine)= potentMid(find(potentMid(:,2),1),1);
               catch %If current line/line duplicates LACK a line that's larger than previous, then don't report it
                   iCellExpand(iSeq,currLine) = NaN;
               end   
           %If current line contains real integers && if previous is NaN, then refer to two lines back     
           elseif isfinite(potentMid) & isnan(iCellExpand(iSeq,currLine-1))
              potentMid(:,2) = potentMid(:,1) >= iCellExpand(iSeq,currLine-2); %Logicals - Ask which line is greater than or equal to two lines back
               try %If current line/line duplicates have a line that's larger than two lines back, then report into iCellExpand
                   iCellExpand(iSeq,currLine)= potentMid(find(potentMid(:,2),1),1);
               catch %If current line/line duplicates LACK a line that's larger than previous, then don't report it
                   iCellExpand(iSeq,currLine) = NaN;
               end
           %If current line is NaN 
           else 
               iCellExpand(iSeq,currLine) = NaN; 
           end
       end
       
       %% For lines that are the end of the holes (6, 10, 14, 18, 22, 26) 
       %Same situation as for the middle of the holes. 
       %Not: for simplicity, will not combine with midholes because it's easier to see particularly referenced increments like -2,+2 vs. -3,+1 etc.

       endHole = 6:4:26;
       for iEHole = 1:6
       currLine = endHole(iEHole);
       potentEnd = find(cellInfoLane([iCellExpand(iSeq,currLine-3):iCellExpand(iSeq,currLine+1)])==currLine);
       potentEnd = potentEnd-1+iCellExpand(iSeq,currLine-3); %adjust index to full array cellInfo numbering, will only work if its a real integer
   
       
           %If current line contains real integers && if previous line
           %contains real integers
           if isfinite(potentEnd) & isfinite(iCellExpand(iSeq,currLine-1))
               potentEnd(:,2) = potentEnd(:,1) > iCellExpand(iSeq,currLine-1); %Logicals - Ask which line is larger than previous
               try %If current line/line duplicates have a line that's larger than previous, then report into iCellExpand
                   iCellExpand(iSeq,currLine)= potentEnd(find(potentEnd(:,2),1),1);
               catch %If current line/line duplicates LACK a line that's larger than previous, then don't report it
                   iCellExpand(iSeq,currLine) = NaN;
               end   
           %If current line contains real integers && if previous is NaN, then refer to two lines back     
           elseif isfinite(potentEnd) & isnan(iCellExpand(iSeq,currLine-1))
              potentEnd(:,2) = potentEnd(:,1) >= iCellExpand(iSeq,currLine-2); %Logicals - Ask which line is greater than or equal to two lines back
               try %If current line/line duplicates have a line that's larger than two lines back, then report into iCellExpand
                   iCellExpand(iSeq,currLine)= potentEnd(find(potentEnd(:,2),1),1);
               catch %If current line/line duplicates LACK a line that's larger than previous, then don't report it
                   iCellExpand(iSeq,currLine) = NaN;
               end
           %If current line is NaN 
           else 
               iCellExpand(iSeq,currLine) = NaN; 
           end
       end       
       


       
 
% At this point, all indices for lines 1-27 should be filled in for the CURRENT cell in iCellExpand in this current lane
% Begin transfer into laneData for current cell, and then go back to finding the 1-27
% sequence for the next cell, and so on and so forth. 

%% %%%%%%%%%% Begin transferring over information into laneData
%THIRD BIG FOR LOOP - LOOP THROUGH EACH CELL
            for transfLine = 1:27    
 
            
                    %%%%%%%%%% If current line is empty a.k.a. a cell is missing one of the horizontal lines reported,
                    %report into matrix as not a number
                    if isnan(iCellExpand(iSeq, transfLine))

                    
                    %Fill in all 9 features in laneData as NaN
                    laneData(iSeq, transfLine, 1:10) = NaN;
                        
                    % For reference, 1 - Frame number
                    % 2 - Cell's area to the entry "behind" the frame
                    % 3 - Diameter (from axis lengths)
                    % 4 - Eccentricity                   
                    % 5 - Circularity
                    % 6 - Perimeter 
                    % 7 - Orientation
                    % 8 - Major Axis
                    % 9 - Minor Axis
                    % 10 - Time (added in next section)
           
                    else  
                    %%%%%%%%%% If current line contains a number a.k.a. cell has the horizontal line properly reported

                    %Reference number for the big array, cellIndex 
                    cellIndex = iCellExpand(iSeq, transfLine); %can minimize this line if desired
                    
                    % Frame number
                    laneData(iSeq, transfLine, 1) = cellInfo{lane}(cellIndex,1);
                    
                    % Write the cell's area to the entry "behind" the frame
                    laneData(iSeq, transfLine, 2) = cellInfo{lane}(cellIndex,4);
              
                    % Diameter (from axis lengths)
                    laneData(iSeq, transfLine, 3) = cellInfo{lane}(cellIndex,8); 
                    %+ cellInfo{lane}(cellIndex,6))/2;
                    
                    % Eccentricity
                    %laneData(iSeq, transfLine, 4) = sqrt(1 - (((cellInfo{lane}(cellIndex,6))^2) / ((cellInfo{lane}(cellIndex,5))^2)));
                    
                    % Circularity
                    laneData(iSeq, transfLine, 5) = cellInfo{lane}(cellIndex,5);
                    
                    % Perimeter 
                    laneData(iSeq, transfLine, 6) = cellInfo{lane}(cellIndex,6);
                    
                    % Orientation
                    laneData(iSeq, transfLine, 7) = cellInfo{lane}(cellIndex,7);
                    
                    % Major Axis
                    laneData(iSeq, transfLine, 8) = cellInfo{lane}(cellIndex,8);
           
                    % Minor Axis
                    laneData(iSeq, transfLine, 9) = cellInfo{lane}(cellIndex,9);
                    
                    % Time 
                    %gets added below after laneData is finished inputting all
                    %the frames

                    
               
                    end 
           
            end
            
            
    end

    
    
    
    
    % At this point, laneData should be filled with all pertinent information for ALL cells in this current lane
    %% Cleans up data and gets rid of ghost cells     
    % Because less filters are needed to clean up data, there's not a need for a user-defined function. Replaces the old CleanData.m script

    %Input lane number
    laneData(:,33,1) = lane;

     % Input total time 
    for timeIndex = 2:27
    laneData(:, timeIndex, 10) = (laneData(:, timeIndex, 1) - laneData(:, 1, 1))*(1000/framerate);
    end
     

    % CLEANING FILTER here
    [cleanerIndex, ~] = find(laneData(:,27,1) ~= 0 & laneData(:, 7, 10) > 0);
    laneDataClean = laneData(cleanerIndex,:,:);


    
%% Transfer into trackingData array which will contain all the laneDatas for lanes 1-16
    trackingData{1,lane} = laneDataClean;
    
  


end
%% For ease of transferring data
unpairedTransitData = double(vertcat(trackingData{1, 1:16}));


 
    
%% OUTPUT: for compMulti32L 
% compMulti32L contains all of filtered, data-cleaned data points
% including measurements of the following metrics at each of the 32
% horizontal lines
    
compMulti32L = cell(2,11);
compMulti32L{2,1} = 'Frame';
compMulti32L{2,2} = 'Total Time (ms)';
compMulti32L{2,3} = 'Ellipse Area';
compMulti32L{2,4} = 'Diameter';
compMulti32L{2,5} = 'Circularity';
compMulti32L{2,6} = 'Perimeter';
compMulti32L{2,7} = 'Orientation';
compMulti32L{2,8} = 'Major Length';
compMulti32L{2,9} = 'Minor Length';
compMulti32L{2,10} = 'Lane';
compMulti32L{2,11} = currVideoName;

% Frame
compMulti32L{1,1}= unpairedTransitData(:,:,1);

% Total time 
compMulti32L{1,2}= unpairedTransitData(:,:,10);


% Ellipse Area
compMulti32L{1,3}= unpairedTransitData(:,:,2);

% Diameter
compMulti32L{1,4}= unpairedTransitData(:,:,3); 

% Circularity
compMulti32L{1,5}= unpairedTransitData(:,:,5); 

% Perimeter
compMulti32L{1,6}= unpairedTransitData(:,:,6); 

% Orientation
compMulti32L{1,7}= unpairedTransitData(:,:,7); 
    
% Major length
compMulti32L{1,8}= unpairedTransitData(:,:,8);

% Minor length
compMulti32L{1,9}= unpairedTransitData(:,:,9);

% Lane  
compMulti32L{1,10}= unpairedTransitData(:,33,1);
 
%% OUTPUT: for compMulti32L_SizeG 
% compMulti32L_SizeG contains similar data as compMulti32L except cells that are within the
% size gating boundaries

% % Logical indexing
% iSizeGate = compMulti32L{1,4}(:,1) > llSizeG & compMulti32L{1,4}(:,1) < ulSizeG;
% 
% % Initialize
% compMulti32L_SizeG = cell(2,11);
% compMulti32L_SizeG(2,:) = compMulti32L(2,:);
% 
% % Copy over information of size gated cells
% compMulti32L_SizeG{1,1} = compMulti32L{1,1}(iSizeGate,:);
% compMulti32L_SizeG{1,2} = compMulti32L{1,2}(iSizeGate,:);
% compMulti32L_SizeG{1,3} = compMulti32L{1,3}(iSizeGate,:);
% compMulti32L_SizeG{1,4} = compMulti32L{1,4}(iSizeGate,:);
% compMulti32L_SizeG{1,5} = compMulti32L{1,5}(iSizeGate,:);
% compMulti32L_SizeG{1,6} = compMulti32L{1,6}(iSizeGate,:);
% compMulti32L_SizeG{1,7} = compMulti32L{1,7}(iSizeGate,:);
% compMulti32L_SizeG{1,8} = compMulti32L{1,8}(iSizeGate,:);
% compMulti32L_SizeG{1,9} = compMulti32L{1,9}(iSizeGate,:);
% compMulti32L_SizeG{1,10} = compMulti32L{1,10}(iSizeGate,:);

    
%%
disp('End of ProcessTrackingData')



            
            

