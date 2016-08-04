% This script extracts the timing of stimulus presentations relative to the
% first timepoint. It finds the time of the played sounds, gets the unique
% entries from the played sounds and cleans the timing variable of the
% repeated sounds.
clear

sub = {
    '02'
    '05'
    '08'
    '10'
    '15'
    '19'
    '21'
    '24'
    };

fileName = {
    '-TdMGB_fMRI_run1.log'
    '-TdMGB_fMRI_run2.log'
    '-TdMGB_fMRI_run3.log'
    '-TdMGB_fMRI_run4.log'
    '-TdMGB_fMRI_run5.log'
    };

TR = 1.6;  % TR in secs. To calculate regressors. May be omitted if onsets used instead.

% Output directory up to subject code name.
outDir = '/scr/archimedes1/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/sourcedata/';
% The rest of the output directory after subject code name.
outDirEnd = '/ses-spespk/func/';
% Directory of log files.
mainDir = '/scr/archimedes1/Glad/Projects/Top-down_mod_MGB/Experiments/TdMGB_fMRI/DATA/presentation/';
% [fileName,fileFolderPath,~] = uigetfile('*.log','Select log file','MultiSelect','off');


for iSub = 1:numel(sub)
    for iRun = 1:numel(fileName)
        fullfilepath = [mainDir, sub{iSub}, fileName{iRun}];
        [dataName, data] = importPresentationLogRT(fullfilepath);
                
        % Set start time at zero and convert to seconds.
        data.time = (data.time - data.time(1))/10000;
        data.rt = data.rt/10000;
        data.time_4 = (data.time_4 - data.time_4(1))/10000;
        
        % Find time of instruction pictures.
        timeOfInstruction = data.time(strcmp(data.event_type, 'Picture'));
        % Find time of played sounds
        timeOfSound = data.time(strcmp(data.event_type, 'Sound'));
        % Find code of sounds presented
        soundCodes = data.code(strcmp(data.event_type, 'Sound'));
        
        % Since 14 sounds presented per block, acquire start of block in steps of
        % 14 sounds. Block length is calculated from time of first sound in block -
        % time of next picture - 400 ms (the pause after the sound presentation).
        timeOfBlock = timeOfSound(1:14:end);
        durationOfBlock = abs(timeOfBlock(1:end-1) - timeOfInstruction(2:end)) - 0.4;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Since I had no event type in the log file, I need to guess the length of
        % the last block by subtracting the timing of last sound and adding 900 ms.
        durationOfBlock(24) = abs(timeOfBlock(end) - timeOfSound(end)) + 0.9;
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % Block type:
        % 1: vowel
        % 2: speaker vowel
        % 3: consonant
        % 4: speaker consonant
        % Take the first sound presented and extract the first string, then skip
        % the next 13 and do the same for the next.
        count = 1;
        for iBlock = 1:14:length(soundCodes)
            blockType(count, 1) = soundCodes{iBlock}(1);
            switch blockType(count, 1)
                case '1'
                    blockName{1, count} = 'vowel';
                case '2'
                    blockName{1, count} = 'spk_vow';
                case '3'
                    blockName{1, count} = 'consonant';
                case '4'
                    blockName{1, count} = 'spk_con';
            end
            count = count + 1;
        end
        
        % Separate blocks to get four columns.
        vowelBlocks = timeOfBlock(strcmp(blockName, 'vowel'));
        consBlocks = timeOfBlock(strcmp(blockName, 'consonant'));
        spkVowBlock = timeOfBlock(strcmp(blockName, 'spk_vow'));
        spkConBlock = timeOfBlock(strcmp(blockName, 'spk_con'));
        
        vowelDur = durationOfBlock(strcmp(blockName, 'vowel'));
        consDur = durationOfBlock(strcmp(blockName, 'consonant'));
        spkVowDur = durationOfBlock(strcmp(blockName, 'spk_vow'));
        spkConDur = durationOfBlock(strcmp(blockName, 'spk_con'));
        
        % Extract timing of hits, misses, and false alarms
        timeOfHit = data.time(strcmp(data.stim_type, 'hit'));
        timeOfMiss = data.time(strcmp(data.stim_type, 'miss'));
        timeOfFalse = data.time(strcmp(data.stim_type, 'false_alarm'));
        
        % Extract reaction times.
       reacTimeOfHit = data.rt(strcmp(data.type, 'hit'));
       reacTimeOfFalse = data.rt(strcmp(data.type, 'false_alarm'));
        
        % Create cell arrays for SPM and save as .mat file.
        names = {'speech_vowel', 'speech_consonant', 'speaker_vowel', 'speaker_consonant',...
            'ifnstruction'};%, 'Hits', 'Misses', 'False Alarms'};
        onsets = {vowelBlocks, consBlocks, spkVowBlock, spkConBlock, ...
            timeOfInstruction};%, timeOfHit, timeOfMiss, timeOfFalse};
        durations = {vowelDur, consDur, spkVowDur, spkConDur, ...
            ones(1, length(timeOfInstruction))};%, ones(1, length(timeOfHit)), ...
        %ones(1, length(timeOfMiss)), ones(1, length(timeOfFalse))};
        fullOutDir = [outDir, 'sub-', sub{iSub}, outDirEnd];
        outName = sprintf('%s/sub-%s_task-spespk_run-%i_conditions.mat', fullOutDir, sub{iSub}, iRun);
        save(outName,'names','durations','onsets')
        
        % Create a table and save it as a tab-delimited file.
        onset = [vowelBlocks; consBlocks; spkVowBlock; spkConBlock; ...
            timeOfInstruction];
        duration = [vowelDur; consDur; spkVowDur; spkConDur; ...
            ones(length(timeOfInstruction), 1)];
        trial_type = [repmat('speech_vowel     ', length(vowelBlocks), 1); ...
                      repmat('speech_consonant ', length(consBlocks), 1); ...
                      repmat('speaker_vowel    ', length(spkVowBlock), 1); ...
                      repmat('speaker_consonant', length(spkConBlock), 1); ...
                      repmat('instruction      ', length(timeOfInstruction), 1)];
        T = table(onset, duration, trial_type);
        outName = sprintf('%s/sub-%s_task-spespk_run-%i_events.tsv', fullOutDir, sub{iSub}, iRun);
        writetable(T,outName,'Delimiter','\t','FileType', 'text')
        
        % Extract name and time of each sound event.
        soundEvent = data.code_3(strcmp(data.event_type_2, 'Sound'));
        soundEventTime = data.time_4(strcmp(data.event_type_2, 'Sound'));
        soundEventType = data.type(strcmp(data.event_type_2, 'Sound'));
        soundEventReacTime = data.rt(strcmp(data.event_type_2, 'Sound'));
        T = table(soundEvent, soundEventTime, soundEventType, soundEventReacTime);
        outName = sprintf('%s/sub-%s_task-spespk_run-%i_individual-events.tsv', fullOutDir, sub{iSub}, iRun);
        writetable(T,outName,'Delimiter','\t','FileType', 'text')
    end
end
% % Calculate regressors.
% names = {'hits', 'misses', 'false_alarms'};
% R = zeros(326, 3);
% R(round(timeOfHit/TR), 1) = 1;
% R(round(timeOfMiss/TR), 2) = 1;
% R(round(timeOfFalse/TR), 3) = 1;
% save('P01_hit_miss_false_regressors.mat','names','R')

% % Find repetitions
% code = data.code(strcmp(data.event_type, 'Sound'));
% [~, idx1, idx2] = unique(code);  % Get indices of unique entries.
% timeOfSound = sort(timeOfSound(idx1)./10000.0);
