%% Detemine reuniens stimulation frequency using previous recording rats. 
% 1. Clean lfp data
% 2. Power analysis
% 3. Visualize data

%% Clean lfp data
%remote desktop
datafolder = '\\plura4\griffinlab\01.Experiments\John n Andrew\Dual optogenetics w mPFC recordings\All Subjects - DNMP\Good performance\Medial Prefrontal Cortex';
%other
%datafolder = 'X:\01.Experiments\John n Andrew\Dual optogenetics w mPFC recordings\All Subjects - DNMP\Good performance\Medial Prefrontal Cortex';
cd(datafolder); % change directory so  matlab can see data

%get lfp
ratID{1} = 'BabyGroot';
ratID{2} = 'Meusli';
CSC{1} = 'CSC14'; %BabyGroot wire
CSC{2} = 'CSC2'; %Muesli wire
lfp=[];
for rati = 1:length(ratID)
    ratDir= [];
    ratDir = [datafolder,'/',ratID{rati}];
    cd(ratDir);
    
    % over sessions
    dir_content = [];
    dir_content = dir(ratDir);
    dir_content = extractfield(dir_content,'name');
    remIdx = contains(dir_content,'.mat') | contains(dir_content,'.');
    dir_content(remIdx)=[];
    sessIDs = dir_content;
    
    templfp=[]; 
    %get lfp (stem->t entry)
    for sessi=1:length(sessIDs)
        sessDir = [ratDir,'\',sessIDs{sessi}];
        cd(sessDir)
        
        re = []; reTS = [];
        [re,reTS] = getLFPdata(sessDir,CSC{rati},'Events');
        
        Int = [];
        load('Int_file')
        
        %get lfp
        for triali = 1:size(Int,1)
            try
                idx = find(reTS>Int(triali,1) & reTS<Int(triali,5)); %stem to t entry
                templfp{sessi}{triali}(1,:) = re(idx);
            catch
                templfp{sessi}{triali} = [];
            end
        end
        disp(['Completed with ', ratID{rati}, ' session ', num2str(sessi),'/',num2str(length(sessIDs))])
    end
    lfp{rati}= horzcat(templfp{:});
end

% look through lfp, exclude trials w/ poor signal
counter = 0;
figure('color','w')
idx2keep{1}=[];
idx2keep{2}=[];
for rati = 1:length(lfp)
    for triali = 1:length(lfp{rati})
        counter = counter + 1;
        subplot(15,2,counter); hold on
        
        % plot data
        plot(lfp{rati}{triali}(1,:),'r');
        
        % plot markers
        ylimits = ylim; xlimits = xlim;
        
        axis tight
        box off
        axis off
        
        % amount of data processed
        timeProcessed = size(lfp{rati}{triali},2)/2000;
        
        % provide info about artifact saturation
        title(['Index #',num2str(triali),' | ',num2str(round(timeProcessed)),'s of data'],'FontSize', 8) ;
        
        if counter == 30 || triali == length(lfp{rati})
            idx2keep{rati} = horzcat(idx2keep{rati},str2num(input('Enter which indices to include ','s')));
            close;
            figure('color','w');
            set(gcf,'Position', get(0,'Screensize'))
            counter = 0;
        end
    end
end

cd(getCurrentPath);
lfpClean.babyGroot = lfp{1}(idx2keep{1});
lfpClean.muesli = lfp{2}(idx2keep{2});
save('lfpClean', 'lfpClean')

%% Power
templfp={};
templfp{1} = lfpClean.babyGroot;
templfp{2} = lfpClean.muesli;

srate  = 2000;
f= 0:0.5:50;
power=[];
for rati = 1:length(templfp)
    for triali =1:length(templfp{rati})
        S=[]; freq=[]; Serr=[];
        [S, freq, Serr] = pwelch(templfp{rati}{triali},[],[],f,srate);
        power{rati}(triali,:) = log10(S);
    end
    normPower{rati} = normalize(power{rati}, 2, 'range');
end

%find max theta power
idxFtheta = f>=6 & f<=12; %index theta freq
for rati =1:length(power)
    thetaPower=[]; maxTheta=[];
    thetaPower = power{rati}(:,idxFtheta); %find theta 
    for triali=1:size(thetaPower,1)
       maxFreq{rati}(triali) = f(power{rati}(triali,:)==max(thetaPower(triali,:)));
    end
end

%bar plot, peak theta
data2plot = []; data2plot{1} = maxFreq{1}; data2plot{2} = maxFreq{2};
figure('color','w')
multiBarPlot(data2plot,[{'Baby Groot'} {'Muesli'}],'Frequency at Peak Theta Power (Hz)','n')
%7.5 for Re stimulation

%visualize power distribution
figure('Color', 'w'); hold on;
shadedErrorBar(f,mean(power{1}),stderr(power{1},1),'m',0);
shadedErrorBar(f,mean(power{2}),stderr(power{2},1),'g',0);
xlim([0,20])
legend({'Pink= Baby Groot, Green=Muesli'})
ylabel('log10(power)')
xlabel('Frequency')

%normalized
figure('Color', 'w'); hold on;
shadedErrorBar(f,mean(normPower{1}),stderr(normPower{1},1),'m',0);
shadedErrorBar(f,mean(normPower{2}),stderr(normPower{2},1),'g',0);
xlim([0,20])
legend({'Pink= Baby Groot, Green=Muesli'})
ylabel('normalized log10(power)')
xlabel('Frequency')


