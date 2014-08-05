function EyeData=ProcessEyePosition(EyeData)

global configData;

%initialise xPosPerCondition
for (i=1:configData.numConditions)
    for (k=1:EyeData.samplesPerTrialPerCond(i))
        xPosPerCondition(i).XPositions(k).X=[]; % awkward structure since there could be different lengths per condition
    end
end

% loop over all conditions
for (i=1:configData.numConditions)
    
    % loop over all segments
    for (j=1:size(EyeData.segment,2))
        if (EyeData.segment(j).include==true)
            % get trial start points for each trial in condition for this
            % segment
            trialStartIndices=EyeData.segment(j).trialsPerCondition(i).startIndex;
            
            % for each trial per condition construct array of positional data
            % over all segments
            for (k=1:EyeData.samplesPerTrialPerCond(i))
                % reshape xPosPerCondition
                if (isempty(xPosPerCondition(i).XPositions(k).X))
                    xData=[EyeData.segment(j).angleX(trialStartIndices+k-1)];
                    lengthxData=size(xData,1)*size(xData,2);
                    %reshape xData to 1 row lengthxData columns
                    xData=reshape(xData,1,lengthxData);
                    xPosPerCondition(i).XPositions(k).X=xData;
                else
                    xData=[EyeData.segment(j).angleX(trialStartIndices+k-1)];
                    lengthxData=size(xData,1)*size(xData,2);
                    %reshape xData to 1 row lengthxData columns
                    xData=reshape(xData,1,lengthxData);

                    xPosPerCondition(i).XPositions(k).X=[xPosPerCondition(i).XPositions(k).X xData];
                end
            end
        end
    end
        

end
    
% loop over all conditions
for (i=1:configData.numConditions)
    meanXPos=[];
    stdXPos=[];
    for (j=1:EyeData.samplesPerTrialPerCond(i))
        m=size(xPosPerCondition(i).XPositions(j).X,1);
        n=size(xPosPerCondition(i).XPositions(j).X,2);
        xPos=reshape(xPosPerCondition(i).XPositions(j).X,1,m*n); % make it linear 
        meanXPos(j)=nanmean(xPos);
        stdXPos(j)=nanstd(xPos);
    end
    meanXPerCondition(i).xPos=meanXPos;
    stdXPerCondition(i).xPos=stdXPos;
end

EyeData.eyePositions.meanXPerCondition=meanXPerCondition;

end
