function AnalyseBistable(PerceptReport, Session)
% AnalyseBistable(PerceptReport, Session)

%========================= ANALYSE PERCEPT DURATIONS ======================
% This function takes an Nx2 or Nx3 matrix of perceptual phase durations for a
% bistable stimulus where column 1 contains the time that each event occurred
% and column 2 contains a code for the event, where: 
%       1 = subject reported percept 1
%      -1 = subject reported percept 2
%       0 = catch period onset (optional)
% If catch periods were included, column 3 should contain zeros for button
% presses that occur outside of catch periods and the percept specified by 
% the catch period (1 or -1) for catch period onset and button presses that
% occurred during catch periods.
% Using this information the function ouputs the following in a single figure:
%
%   1) Plot of perceptual state against time (incluidng any catch periods) 
%   2) Plot probability density function (PDF) for percept durations 
%   2) Plot cumulative density function (CDF) for percept durations
%   3) Summary statistics for percept durations, distributions and biases
%   4) Summary statistics for catch trial performance
%
% PDFs and CDFs are fitted with:
%   1) Lognormal distribution fit
%   2) Gamma distribution fit
%   3) Gamma rate distribution fit
% Fit parameters are provided and goodness of fit is tested with Chi-squared
%
% SESSION STRUCTURE FIELDS:
%   Session.Initials: 
%   Session.Labels: Cell containing strings for each of the two percepts in
%           the particular task, in the form: {'Percept1', 'Percept2'}.
%   Session.TrialDuration: Trial duration (seconds)
%   Session.CatchDuration: Catch event duration (seconds)
%   Session.Intermittent: Leave blank for continuous presentation, or provide parameters
%           for intermittent presentation in the form [Ton, Toff].
%   Session.Rate:   set to 1 to analyse perceptual alternation rate, leave blank to
%           analyse perceptual phase duration.  (Rate = 1/Duration).
%   Session.Normalize: set to 1 to view normalized percept phase durations, leave
%           blank for actual phase durations (seconds).
%   
% EXAMPLE: 
% PerceptReport = 
%     1.1027   -1.0000         0  <-- First key press
%     1.7358    1.0000         0
%     2.4022   -1.0000         0
%     3.0187    1.0000         0
%     3.5521         0   -1.0000  <-- Catch event onset
%     6.1176   -1.0000   -1.0000  <-- Key press during catch period
%    15.4976    1.0000         0
%    16.7138   -1.0000         0
%
% REFERENCES:
%   Wallach H, O'Connell DN (1953) The kinetic depth effect. J Exp Psychol
%       45:205-217.
%   Leopold DA, Wilke M, Maier A, Logothetis NK (2002) Stable perception of 
%       visually ambiguous patterns. Nat.Neurosci 5:605-609.
%   Brascamp JW, van Ee R, Pestman WR, van den Berg AV (2005) Distributions 
%       of alternation rates in various forms of bistable perception. J Vis
%       5:287-298.
%        ___  ______  __   __
%       /   ||  __  \|  \ |  \    Aidan P. Murphy - apm909@bham.ac.uk
%      / /| || |__/ /|   \|   \   Binocular Vision Lab
%     / __  ||  ___/ | |\   |\ \  University of Birmingham
%    /_/  |_||_|     |_| \__| \_\
%
% REVISIONS:
% 15/09/2010 - Created by Aidan Murphy (apm909@bham.ac.uk)
% 25/11/2011 - Updated to analyse multi-session data (APM)
%==========================================================================
rootDir = fileparts(mfilename('fullpath'));                            	% Get just the directory path
addpath(fullfile(rootDir,'APMSubfunctions'));                         	% Add APM subfunction folder to path
addpath(genpath(fullfile(rootDir,'APMSubfunctions')));              	% Add subfolders within APM subfunction folder

switch nargin
    case 0
        [filename filepath] = uigetfile('*.mat','Select bistable data to analyse'); 
        load([filepath filename]);
end
if ~exist('PerceptReport', 'var') && exist('Results', 'var')    
    PerceptReport = Results;
end
if ~exist('Session','var')
    fprintf(['The file ''%s'' does not contain session information.\n',...
    'Proceeding with default session parameters.\n'], filename);
    Session.Labels = {'Percept 1', 'Percept 2'};
    Session.Intermittent = 0;
    Session.CatchDuration = 0;
    Session.TrialDuration = PerceptReport(end,1);
    Session.Initials = 'TEST';
    Session.Trial = 99;
end

Session.Rate = 0;
Session.Normalize = 0;

if ~isfield(Session, 'Labels')
    Session.Labels = {'Percept 1', 'Percept 2'};
end

fprintf('\n\n============== Analyzing bistable perceptual report data... ==============\n\n');
fprintf('SESSION DETAILS:\n');
disp(Session);


if max(PerceptReport(:,2))> 1                                   % If values of -1 and 1 were not used...
    PerceptReport(PerceptReport(:,2)>1,2) = -1;
    PerceptReport(PerceptReport(:,3)>1,3) = -1;
end


PerceptDurations = diff(PerceptReport(:,1));                    % Do not count last perceptual phase period, since it was cut short by the end of the trial
PerceptDurations(:,2) = PerceptReport(1:end-1,2);               % Record reported percepts


%======================== ANALYSE CATCH PERIOD DATA =======================
if Session.CatchDuration ~= 0
    CatchOnsets = find(PerceptReport(:,2)==0);                                          % Find events that were catch event onsets
    if PerceptReport(end,3)~=0                                                          % If the trial ended during a catch event...
        CatchOnsets(end) = [];                                                          % ...don't count the final catch event
    end
    TotalCatches = numel(CatchOnsets);                                                  % Calculate how many catch events occured
    PreviousResponse = PerceptReport(CatchOnsets-1, 2);                                 % Find the percept immediately prior to each catch event onset
    CorrectReject = 0; MissedCatch = 0; HitCatch = 0; FalsePositive = 0;
    Response2correct = 0; 
    for n = 1:TotalCatches
        if PreviousResponse(n) == PerceptReport(CatchOnsets(n),3)                       % If catch event answer was same as previously reported percept
            if PerceptReport(CatchOnsets(n)+1,3) == 0                                   % ...and if no response was given during the catch event...
                CorrectReject =  CorrectReject+1;                                       % mark as CORRECT REJECTION
            elseif PerceptReport(CatchOnsets(n)+1,3) ~= 0                               % ...or if a response was given during the catch event...
                FalsePositive = FalsePositive+1;                                        % mark as FALSE POSITIVE
                if PerceptReport(CatchOnsets(n)+2,3) ~= 0                               % If more than one response was given during catch event
                    Response2correct = Response2correct+1;                              % mark as 2nd response correct
                end
            end
        elseif PreviousResponse(n) ~= PerceptReport(CatchOnsets(n),3)                   % If catch event answer was different from previously reported percept                                                                            % If catch event answer was different to currently reported percept
            if PerceptReport(CatchOnsets(n)+1,3) == 0                                   % ...and if no response was given during the catch event...
                MissedCatch =  MissedCatch+1;                                           % mark as MISS
            elseif PerceptReport(CatchOnsets(n)+1,3) == PerceptReport(CatchOnsets(n)+1,2)% ...or if the first response given was correct
                HitCatch =  HitCatch+1;                                                 % mark as HIT
                if PerceptReport(CatchOnsets(n)+2,3) ~= 0                               % If more than one response was given during catch event
                    FalsePositive = FalsePositive + 1;                                  % Mark as FALSE POSITIVE
                    HitCatch = HitCatch-1;                                              % mark as 2nd response invalidates hit
                end
            end
        end
    end
    CorrectCatches = CorrectReject + HitCatch;
    CatchAccuracy = CorrectCatches/TotalCatches;
    
    %--------- Remove catch related data from percept duration data
    CatchPeriodEvents = find(PerceptReport(:,3)~=0);
    PreCatchEvents = find(PerceptReport(:,2)== 0)-1;
    PerceptDurations([CatchPeriodEvents; PreCatchEvents],:) = [];
    
    CatchOnsetData = PerceptReport(CatchOnsets,[1 3]);                      % Save information about catch period onsets
    PerceptReport(PerceptReport(:,2)==0, :) = [];                           % remove catch period onsets from perceptual report data
    
    %--------- Add data points to produce square wave plot of catch periods
    PlotCatch(1,:) = [0 0];
    for Catch = 1:TotalCatches
        PlotCatch((Catch*4)-2,:)=[CatchOnsetData(Catch,1)-0.001,0];
        PlotCatch((Catch*4)-1,:)=CatchOnsetData(Catch,:);
        PlotCatch((Catch*4),:)=[CatchOnsetData(Catch,1)+ Session.CatchDuration,CatchOnsetData(Catch,2)];
        PlotCatch((Catch*4)+1,:)=[CatchOnsetData(Catch,1)+Session.CatchDuration+0.001,0];
    end
    PlotCatch(end+1,:) = [Session.TrialDuration, 0];
   
    
    CatchSummary = sprintf('Catch period accuracy = %.2f %%',CatchAccuracy*100); 
    if CatchAccuracy < 1
        Catches = sprintf('Catch event errors were due to %d misses and %d false positives\n', MissedCatch, FalsePositive);
    else
        Catches = ' ';
    end
else
    Catches = ' ';
end

Percept1Durations = PerceptDurations(PerceptDurations(:,2)==1, 1);
Percept2Durations = PerceptDurations(PerceptDurations(:,2)==-1, 1);
PerceptDurations(:,2) = [];
MeanPerceptDur = mean(PerceptDurations);
SEPerceptDur = std(PerceptDurations)/sqrt(numel(PerceptDurations));

%==================== PLOT PERCEPTUAL ALTERNATIONS OVER TIME
PlotReport(1,:)= [0 0]; 
for Report = 1:numel(PerceptReport(:,1))
    PlotReport((Report*2),:)= [PerceptReport(Report,1)-0.001,PlotReport((Report*2)-1,2)];
    PlotReport((Report*2)+1,:)= PerceptReport(Report,1:2);
end
PlotReport(end+1,:)= [Session.TrialDuration,PlotReport(end,2)];

if Session.Intermittent ~= 0                                       % Black out blank periods
    StimulusOn = 0:sum(Session.Intermittent):PerceptReport(end,1);
    StimulusOff = Session.Intermittent(1):sum(Session.Intermittent):Session.TrialDuration;
    
end

f(1) = subplot(3,1,1);                                                          % Create subplot 
if Session.CatchDuration ~= 0
    plot(PlotCatch(:,1),PlotCatch(:,2),'-r','LineWidth',3);                     % Plot catch event data
end
hold on;
plot(PlotReport(:,1),PlotReport(:,2),'-b','LineWidth',2);                       % Plot percept alternation data
set(gca,'fontsize',10);  
set(gca, 'YTick',-1:1:1);                                               
set(gca, 'ylim',[-1.25 1.25]);
Ylabel = {Session.Labels{1},'Ambiguous',Session.Labels{2}};
set(gca, 'YTickLabel',Ylabel);                                                  % Add y-axis tick labels
set(gca, 'xlim',[0 Session.TrialDuration]);
xlabel('Time (seconds)', 'FontSize', 12)                                        % Add x- and y-axis titles
ylabel('Reported percept', 'FontSize', 12)
% legend('Catch events','Perceptual report', 'Location', 'NorthOutside');         % Add legend 
zoom xon;                                                                       % Enable zoom on x axis only
 

%==================== TALLY AND REMOVE PERCEPT DURATION OUTLIERS
MinimumDuration = 0.1;
MaximumDuration = 60;
ShortOutliers = find(PerceptDurations < MinimumDuration);
LongOutliers = find(PerceptDurations > MaximumDuration);
PerceptDurations(ShortOutliers) = [];
PerceptDurations(LongOutliers) = [];


%==================== CALCULATE PERCEPTUAL ALTERNATION RATE (Hz)
% if Rate == 1
    SwitchRates = zeros(numel(PerceptDurations),1);
    for n = 1:numel(PerceptDurations)
        SwitchRates(n) = 1/PerceptDurations(n);
    end
% end


MeanDuration = mean(PerceptDurations);
StdDuration = std(PerceptDurations);
MinDuration = PerceptDurations(1);
MaxDuration = PerceptDurations(end);
TotalPhases = numel(PerceptDurations);

MeanSwitchRate = mean(SwitchRates);
MaxRate = SwitchRates(1);
MinRate = SwitchRates(end);
MeanRate = mean(SwitchRates);
StdRate = std(SwitchRates);


%================== Plot probability density functions (PDFs)==============
if Session.Rate == 0                %------------------------------------------First loop processes ABSOLUTE durations (s)
    Durations = PerceptDurations;
    Rates = SwitchRates;    
    BinSize = 1;
    AnalysisFilename = strcat(Session.Initials, '_DurationAnalysis'); 
    XLabel = 'Percept Duration (s)';
elseif Session.Rate == 1
    Durations = SwitchRates;    
    Rates = PerceptDurations;
    BinSize = 1;
    AnalysisFilename = strcat(Session.Initials, '_RateAnalysis'); 
    XLabel = 'Switch Rate (Hz)';
end

if Session.Normalize == 1            %------------------------------------------Second loop processes RELATIVE durations
    Durations = PerceptDurations/mean(PerceptDurations);
    BinSize = 0.1;
    AnalysisFilename = strcat(AnalysisFilename, '_Relative');
    Rates = zeros(numel(PerceptDurations),1);
    for n = 1:numel(Durations)
        Rates(n) = 1/Durations(n);
    end
    XLabel = 'Normalized Percept Duration';
    if Session.Rate == 1
        XLabel = 'Normalized Alternation Rate';
    end
end

f(2) = subplot(3,2,3);                                                  % Create subplot 
bins = 0:BinSize:max(Durations);
[n,xout] = hist(Durations, bins);                                       
n = n/(numel(Durations)*BinSize);                                       % For n = probability of a given phase duration 
h1 = bar(xout,n, 'style', 'histc');
set(gca, 'YTick',-1:1:1);                                               
set(gca, 'ylim',[-1.4 1.4]);
set(gca, 'YTickLabel',{PerceptLabels{1},'',PerceptLabels{2}});        % Add y-axis tick labels

set(h1,'facecolor','w');
set(gca,'fontsize',10);                                                 
xlabel(XLabel, 'FontSize', 12)                                          % Add x- and y-axis titles
ylabel('Frequency', 'FontSize', 12)
title('Probability Density Function', 'FontSize', 14, 'FontWeight','bold')
Ylim = get(gca, 'ylim');
Xlim = get(gca, 'xlim');
Xticks = 0:0.02:Xlim(2);
hold on;

alpha = 0.05;

%================== Fit LOGNORMAL duration distribution to data
[parmhat, parmci] = lognfit(Durations);        	% 'pci' are confidence intervals (lower bound; upper bound)
LogMu = parmhat(1);                            	% 'parmhat' returns estimated mu and sigma parameters
LogSigma = parmhat(2);
[LogMean,LogVar] = lognstat(LogMu,LogSigma);   	% obtain mean and variance for lognormal distribution
logX = 0:0.02:Xlim(2);
logPDF = lognpdf(logX,LogMu,LogSigma);
logCDF = logncdf(logX,LogMu,LogSigma);

%================== Fit GAMMA duration distribution to data
[phat,pci] = gamfit2(Durations, alpha);         % 'phat' returns maximum likelihood estimates (MLEs), 'pci' are confidence intervals (lower bound; upper bound)
GamK = phat(1);                                 % shape parameter (k)
GamLambda = phat(2);                            % scale parameter (theta) 
[GamMean,GamVar] = gamstat(GamK,GamLambda);     % obtain mean and variance for gamma distribution
gamX = 0:0.02:Xlim(2);
gamPDF = gampdf(gamX,GamK, GamLambda);
gamCDF = gamcdf(gamX,GamK, GamLambda);

%================== Fit GAMMA RATE distribution to data
[Rphat,Rpci] = gamfit2(Rates, alpha);           % Fit gamma distribution to SWITCH RATE data
RGamK = Rphat(1);                               % shape parameter (k)
RGamLambda = Rphat(2);                          % scale parameter (lambda) 
[RGamMean,RGamVar] = gamstat(RGamK,RGamLambda); % obtain mean and variance for gamma rate distribution
RgamX = 0:0.02:Xlim(2); 
RategamPDF = gampdf(RgamX,RGamK, RGamLambda);
RgamPDF = zeros(numel(RgamX),1);
for n = 1:numel(RgamX)
    X(n) = 1/(RgamX(n));
    RgamPDF(n) = (1/((RGamLambda^RGamK)*gamma(RGamK))) * X(n)^(RGamK-1) * exp(-X(n)/RGamLambda);
    RgamPDF(n) = RgamPDF(n)/(RgamX(n))^2;
end

    %------------- Check gamma fit to rates by plotting:
%         BinSize = 0.1;    
%         bins = 0:BinSize:max(Rates);
%         [n,xout] = hist(Rates, bins);
%         n = n/(numel(Rates)*BinSize);
%         h2 = bar(xout,n, 'style', 'histc');
%         xlabel('Switch Rate (Hz)', 'FontSize', 12, 'FontWeight','bold'); 
%         RXlim = get(gca, 'xlim');
%         RatesX = 0:0.02:RXlim(2);
%         hold on;
%         
%         [Rphat,Rpci] = gamfit(Rates);                  % 'Rphat' returns maximum likelihood estimates (MLEs), 'Rpci' are confidence intervals (lower bound; upper bound)
%         RGamK = Rphat(1);                              % shape parameter (k)
%         RGamLambda = Rphat(2);                         % scale parameter (lambda) 
%         [RGamMean,RGamVar] = gamstat(RGamK,RGamLambda);% obtain mean and variance for gamma rate distribution
%         GamRatePDF = gampdf(RatesX,RGamK, RGamLambda);
%         RatesPDF = plot(RatesX,GamRatePDF, '-.g'); 


%================== Plot all PDF fits
PDF = plot(logX,logPDF, '-r', gamX,gamPDF, '-b', RgamX,RgamPDF, '-g', 'LineWidth', 2);
l = legend(PDF, {'Lognormal', 'Gamma', 'Gamma rate'}, 3);
set(l, 'Location','NorthEast');
set(l, 'Box', 'off');

%================== Add distribution notes
LogNotes = strcat('Lognormal: \mu = ', num2str(LogMu, '%10.3f'), ', \sigma = ', num2str(LogSigma, '%10.3f'));
GamNotes = strcat('Gamma duration: r = ', num2str(GamK, '%10.3f'), ', \lambda = ', num2str(GamLambda, '%10.3f'));
RGamNotes = strcat('Gamma rate: r = ', num2str(RGamK, '%10.3f'), ', \lambda = ', num2str(RGamLambda, '%10.3f'));
Notes = {LogNotes; GamNotes; RGamNotes};
text(Xlim(2)/2,(Ylim(2)-(Ylim(2)/3)), Notes);


%===================== PLOT CUMULATIVE DISTRIBUTION FUNCTIONS (CDFs)
f(3) = subplot(3,2,4);
[h,stats] = cdfplot(Durations);                                                   % Plot empirical data CDF
set(h,'Color','k','LineWidth',1)
set(gca,'fontsize',10);
loop = 1;
if loop == 1
    xlabel('Percept Duration (s)', 'FontSize', 12)           % Add x- and y-axis titles
elseif loop == 2
    xlabel('Relative Percept Duration', 'FontSize', 12)      % Add x- and y-axis titles
end
ylabel('Cumulative Probability', 'FontSize', 12)
title('Cumulative Density Function', 'FontSize', 12, 'FontWeight','bold')
hold on;

%     CDF = plot(logX,logCDF, '-r', gamX,gamCDF, '-b', RgamX,RgamCDF, '-g');
CDF = plot(logX,logCDF, '-r', gamX,gamCDF, '-b');                                 % Plot all CDF fits
set(CDF, 'LineWidth', 2);
%     l = legend(gca, 'Empirical data', 'Lognormal', 'Gamma', 'Gamma rate', 3);
l = legend(gca, 'Empirical data', 'Lognormal', 'Gamma', 3);
set(l, 'Location','SouthEast');
set(l, 'Box', 'off');
grid off;

%================== Chi square test for goodness of fit for each distribution
[LognH,LognP,LognStats] = chi2gof(PerceptDurations, 'cdf', {'logncdf',LogMu,LogSigma});
[GamH,GamP,GamStats] = chi2gof(PerceptDurations, 'cdf', {'gamcdf',GamK, GamLambda});
[RGamH,RGamP,RGamStats] = chi2gof(PerceptDurations, 'cdf', {'gamcdf',RGamK, RGamLambda});

%================== Save parameter estimates, confidence intervals and chi statistics to .mat file
LogParm = struct('mu', LogMu, 'muConfInt', [parmci(1,1), parmci(2,1)], 'sigma', LogSigma, 'sigConfInt', [parmci(1,2), parmci(2,2)]);
GamParm = struct('k', GamK, 'kConfInt', [pci(1,1), pci(2,1)], 'lambda', GamLambda, 'lambdaConfInt', [pci(1,2), pci(2,2)]);
RGamParm = struct('k', RGamK, 'kConfInt', [Rpci(1,1), Rpci(2,1)], 'lambda', RGamLambda, 'lambdaConfInt', [Rpci(1,2), pci(2,2)]);
LogChi2 = struct('Chi2', LognStats.chi2stat, 'p', LognP, 'N', TotalPhases, 'dF', LognStats.df);
GamChi2 = struct('Chi2', GamStats.chi2stat, 'p', GamP, 'N', TotalPhases, 'dF', GamStats.df);
RGamChi2 = struct('Chi2', RGamStats.chi2stat, 'p', RGamP, 'N', TotalPhases, 'dF', RGamStats.df);
save(AnalysisFilename, 'MeanDuration', 'StdDuration', 'TotalPhases', 'MeanRate', 'StdRate', 'PerceptDurations', 'SwitchRates');
save(AnalysisFilename, 'LogParm', 'GamParm', 'RGamParm', 'LogChi2', 'GamChi2', 'RGamChi2', '-append');

%================== Add statistical notes
LogNote1 = strcat('Lognormal: \mu = ', num2str(LogMu, '%10.3f'), ', \sigma = ', num2str(LogSigma, '%10.3f'));
LogNote2 = strcat('\chi^{2} (', num2str(LognStats.df), ', N = ', num2str(TotalPhases), ') = ', num2str(LognStats.chi2stat, '%10.3f'), ', \itp\rm = ',num2str(LognP, '%10.3f'));
GamNote1 = strcat('Gamma duration: r = ', num2str(GamK, '%10.3f'), ', \lambda = ', num2str(GamLambda, '%10.3f'));
GamNote2 = strcat('\chi^{2} (', num2str(GamStats.df), ', N = ', num2str(TotalPhases), ') = ', num2str(GamStats.chi2stat, '%10.3f'), ', \itp\rm = ',num2str(GamP, '%10.3f'));
RGamNote1 = strcat('Gamma rate: r = ', num2str(RGamK, '%10.3f'), ', \lambda = ', num2str(RGamLambda, '%10.3f'));
RGamNote2 = strcat('\chi^{2} (', num2str(RGamStats.df), ', N = ', num2str(TotalPhases), ') = ', num2str(RGamStats.chi2stat, '%10.3f'), ', \itp\rm = ',num2str(RGamP, '%10.3f'));
LogNotes = {LogNote1; LogNote2};
GamNotes = {GamNote1; GamNote2};
RGamNotes = {RGamNote1; RGamNote2};
% text(20,0.40, LogNotes, 'EdgeColor','red');
% text(20,0.25, GamNotes, 'EdgeColor','blue');
% text(20,0.10, RGamNotes, 'EdgeColor','green');

set(f,'fontsize',12);
rect = Screen('rect', 1);
set(gcf, 'position', rect);                                                              % Resize figure to fill window


%=================== ADD SUMMARY DATA TO FIGURE ===========================
ax = axes('position',[0,0,1,1],'visible','off');
% if Session.EyeLinkOn == 1
%     Blinks = sprintf('Total number of blinks: %d \nTotal duration of blinks: %.2f seconds\n', TotalBlinks, TotalBlinkDuration);
% else
%     Blinks = '*No EyeLink data available*';
% end

FigTitle = sprintf('%s: Trial %d Summary', Session.Initials, Session.Trial);                                      % Print figure title
Heading = text(0.5,0.97, FigTitle,'HorizontalAlignment','center','FontSize',16, 'fontweight','bold');
Summary = sprintf(['Mean percept duration = %.3f seconds (s.d. = %.3f sec)\n',...
    'Bias for percept 1 = %.3f\n',...
    '%.0f %% of catch events were responded to correctly (%d out of %d catch events in total)%s\n%s'],...
    MeanPerceptDur, SEPerceptDur, LeftBias, CatchAccuracy*100, CorrectCatches, TotalCatches, Catches, Blinks);
tx = text(0.1,0.15, Summary,'BackgroundColor',[.9 .7 .7],'Margin',10,'FontSize',16);


%=================== PRINT SUMMARY DATA TO COMMAND LINE ===================
fprintf('\n\n==================== %s, TRIAL %d SUMMARY ========================\n\n', initials, Trial)
fprintf(SwitchSummary);
fprintf('\nCatch trial performance:\n');
fprintf('%.1f %% of catch events were responded to correctly (%d out of %d catch events in total)\n', CatchAccuracy*100, CorrectCatches, TotalCatches);
if PercentCorrectCatches < 100
    fprintf('Catch event errors were due to %d misses and %d false positives\n', MissedCatch, FalsePositive);
end
fprintf('Mean switch rate = %0.2f /second\nTotal voluntary switches = %d\n', SwitchRate, TotalSwitches);
fprintf('\n\n==============================================================\n\n');



% %=========================== SAVE FIGURE ============================
% saveas(gca, figname, 'fig');
% % save plot as Matlab figure
% KbWait;
% close all;
