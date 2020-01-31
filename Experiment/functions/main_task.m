function data=main_task(data,pr,SR,session)

inEEG = true;
isTobii= true;

% %%%%%%%%%%%%%%%%%%%%%
%% INITIALISATION TOBII
% %%%%%%%%%%%%%%%%%%%%%

[obj] = connect_Tobii(isTobii);

% %%%%%%%%%%%%%%%%%%%
%% INITIALISATION EEG
% %%%%%%%%%%%%%%%%%%%
if inEEG && pr == 0
    settings.pport.address   = hex2dec('D050');
    settings.pport.int = 0.001; % in seconds
    
    % create pport object
    pportObj = io32;
    % check status of io32 interface object
    status = io32(pportObj);
    if(~(status==0))
        fprintf('The parallel port interface could not be accessed - abort\n');
        return
    end
    % reset pport
    pport_mrk = 0; io32(pportObj, settings.pport.address, pport_mrk);
end

%% Stuff to define before the experiment really starts

durs=[9];
numtrials=length(data.type);

% Define response keys
KbName('UnifyKeyNames');
Lft=KbName('a');
Rgt=KbName('l');
Ext=KbName('Escape');

deadline=3000;
wrate=0.5;

tiny=5;
col=[0 0 0; 0 0 0];
rw=50;
rewd = [];

% Position bars so they are x degrees from the centre
degrees = 22.5;
middle_x = 70; %middle of bar on x-axis
new_x = 90; % extra shift on x-axis
new_y = round(tand(degrees)*(middle_x + new_x)); %extra shift on y-axis depending on angle and distance from middle


try
    %% Open Screen
    Screen('Preference','SkipSyncTests',2);
    scr_max=max(Screen('Screens'));
    [w, rect] = Screen('OpenWindow', scr_max, 0,[],32,2);
    
    HideCursor;	% Hide the mouse cursor
    center=[rect(3)/2 rect(4)/2];
    leftrect=[center(1) center(2) center(1) center(2)]+[-(100+new_x) (-105-new_y) -(40+new_x) (105-new_y)]; % left bar
    rightrect=[center(1) center(2) center(1) center(2)]+[(40+new_x) (-105-new_y) (100+new_x) (105-new_y)]; % right bar
    tinyrect=[rect(3)/2-tiny center(2)-tiny rect(3)/2+tiny center(2)+tiny]; % fixation cross
    
    Screen('TextFont', w, 'Calibri');
    Screen('TextSize', w , 50 );
    [wl,rect]=Screen('OpenOffscreenWindow', scr_max, 0, leftrect);
     
     %% Instructions
    
    if pr==1; % for practice trials
        
        Screen(w,'FillRect',255);
        Screen('TextSize', w , 50 );
        Screen(w,'DrawText','Welcome!',(rect(3)/2),(rect(4)/2),0);   % draw instuctions
        Screen('TextSize', w , 30 );
        Screen(w,'DrawText','Click to read the instructions...',(rect(3)/2),(rect(4)/2)+250,0);   % draw instuctions
        Screen(w,'Flip');  % write to screen
        press=0;  % wait for mouse press to initiate
        
        while press==0;
            [tmpx tmpy buttons]=GetMouse;
            if any(buttons)
                press=1;
            end
        end
 
        if (SR == 1 && session == 1) || (SR == 0 && session == 2)
            fd = fopen(['functions/Instructions_highframe.m'], 'rt');
        else
            fd = fopen(['functions/Instructions_lowframe.m'], 'rt');
        end
 
        if fd==-1
            error('Could not open Contents.m file in PTB root folder!');
        end
        
        mytext = '';
        tl = fgets(fd);
        lcount = 0;
        
        while (tl~=-1) & (lcount < 48)
            mytext = [mytext tl];
            tl = fgets(fd);
            lcount = lcount + 1;
        end
        
        fclose(fd);
        mytext = [mytext char(10)];
        Screen('TextSize',w, 20);
        [nx, ny, bbox] = DrawFormattedText(w, mytext, 10,'center', 0);
                
        % Show computed text bounding box:
        %Screen('FrameRect', w, 0, bbox);
        Screen('DrawText', w, 'Press space bar to continue.', nx, ny+80, [255, 0, 0, 255]);
        Screen('Flip',w);
        Screen('TextFont', w, 'Calibri');
        Screen('TextSize', w , 50 );
        KbWait;
        while KbCheck; end;
        
    end

    Screen(w,'FillRect',128);  % black screen
    Screen(w,'Flip');        % write to screen
    WaitSecs(1);
    
    % some more stuff to define before experiment really starts
    tic;
    bl=0;
    expstart = 0; % reference variable for timings
    data.repeat_trials = []; % matrix to save trials where eyes have moved
    extra_t = 0; % additional trials to the experiment (defined by size of data.repeat_trials at end of experiment)
    eyes_moved = 0; % counter: if eye tracker freaks out, this will make feedback stop after a while
    
    %% Stimulus presentation
    
    for t=1:numtrials;  % loop through trials
        
        disp(num2str(t));
                
        if t==1 && pr==1 % instructions at start of practice trials
            bl=bl+1;
            
            Screen(w,'FillRect',128);
            Screen(w,'DrawText','Practice trials',(rect(3)/2)+100,(rect(4)/2)+50,0);
            Screen('TextSize', w , 30 );
            Screen(w,'DrawText','Respond with A and L key.',(rect(3)/2)+100,(rect(4)/2)+150,255);
            Screen(w,'DrawText','We start with 6 practice trials',(rect(3)/2)+100,(rect(4)/2)+200,255);
            Screen(w,'DrawText','Press any key to continue...',(rect(3)/2)+100,(rect(4)/2)+350,255);
            Screen(w,'Flip');
            WaitSecs(1);KbWait;
            
            Screen(w,'FillRect',128);
            Screen(w,'Flip');
            WaitSecs(1);

        elseif  mod(t,numtrials/10)==1 && pr==0 % start screen at start of each block in experiment
            
            bl=bl+1;
            Screen(w,'FillPoly',[0 255 0],[100 100; 200 200; 300 300;]);
            
            Screen(w,'FillRect',128);
            Screen(w,'DrawText',['Block ' num2str(bl) '/10'],(rect(3)/2),(rect(4)/2)+50,0);
            
            Screen('TextSize', w , 30 );
            Screen(w,'DrawText','Press any key to continue...',(rect(3)/2)+100,(rect(4)/2)+250,255);
            Screen('TextSize', w , 65 );
            Screen(w,'Flip');
            WaitSecs(1);KbWait;
            
            Screen(w,'FillRect',128);
            Screen(w,'Flip');
            WaitSecs(1);
            
        end
        
        
        % Encode differently for high and low frame, so response = 1 means 'correct' in both frames
        if (SR == 1 && session == 1) || (SR == 0 && session == 2) % HIGH FRAME
            if data.order(t)==0
                lefts=data.left(t,:);
                rights=data.right(t,:);
                pos=[1 2]; % 1 = highest bars, 2 = lowest bars
            else
                lefts=data.right(t,:);
                rights=data.left(t,:);
                pos=[2 1]; % 1 = highest bars, 2 = lowest bars
            end
        else % LOW FRAME
            if data.order(t)==0
                lefts=data.left(t,:);
                rights=data.right(t,:);
                pos=[2 1]; % 1 = lowest bars, 2 = highest bars
            else
                lefts=data.right(t,:);
                rights=data.left(t,:);
                pos=[1 2]; % 1 = lowest bars, 2 = highest bars
            end
        end
        
        % Fixation cross
        Screen(w,'FillRect',128);
        Screen(w,'FillOval',255,tinyrect);
        Screen(w,'Flip');
        
        % Trigger EEG fixation cross (= 2)
        if inEEG && pr == 0
            pport_mrk = 1;
            pport_mrk = pport_mrk + 1;
            % trigger on
            io32(pportObj, settings.pport.address, pport_mrk);
            % wait as required by the amp
            WaitSecs(settings.pport.int);
            % trigger off
            io32(pportObj, settings.pport.address, 0);
            %give the trigger a numerical value
            
            % get reference timing for whole experiment
            if t == 1
                expstart = GetSecs;
            end
            
            WaitSecs(0.004); %changed this from 1, will it matter?
        end
        
        % Start of epoch for eye tracker
        if isTobii && pr==0;
            % 3. Tobii Collect time stamp
            dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
            data.timestampData(t,1) = mlDataNum(1);
        end
        
        WaitSecs(.3);
         
        % Stuff that needs to be defined at the start of each trial       
        sstart=GetSecs; % reference for timing of bars
        j=1; % number of bars
        resp = 0; % response
        pres = zeros(1,length(lefts)); % counter of bars
        press = 0; % how many key presses were given
        keycode=0; % which key was pressed
        out_bounds = 0; % counter of how many times eyes were outside frame around fixation cross
        check_eyes = 0; % check whether eyes are still tracked
        
        % MASK before bars
        for j=1:1;
            
            count=0;
            Screen(w, 'FillRect', [0 0 0], leftrect);
            Screen(w, 'FillRect', [0 0 0], rightrect);
            
            Screen(w, 'FillRect', [50], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
            Screen(w, 'FillRect', [50], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
            Screen(w,'Flip');
            WaitSecs(0.05);
            
        end
        
        % Presentation of bars
        while j<=durs(1);
            
            selapsed=ceil((GetSecs-sstart).*1000); % how much time has elapsed
            
            if selapsed<data.randgap(t,j) % present empty bars in timegap between bars (random between 100-200 ms)
                   
                Screen(w,'FillOval',[0 0 0],tinyrect);                
                Screen(w, 'FillRect', [0 0 0], leftrect);
                Screen(w, 'FillRect', [0 0 0], rightrect);                
                Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                Screen(w,'Flip');
                
                EEG_trigger=1; % only trigger first time a new bar is presented
                
                % check whether eyes are within frame around fixation cross
                if isTobii && pr==0;
                    % 3. Tobii Collect time stamp
                    dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                    if (any(mlDataNum(2:5) <= 0.4) || any(mlDataNum(2:5) >= 0.6)) && ~((mlDataNum(2) == 0 && mlDataNum(3) == 0) || (mlDataNum(4) == 0 && mlDataNum(5) == 0))
                        out_bounds = out_bounds + 1;
                    elseif mlDataNum(2:5) == 0
                        check_eyes = check_eyes + 1;
                    end
                end
                
                selapsed=ceil((GetSecs-sstart).*1000); % has deadline of this part already passed?
 
            elseif selapsed>=data.randgap(t,j) && selapsed<data.randgap(t,j) + 350; % between ~150 and ~500 ms present the bars
 
                Screen(w,'FillOval',[0 0 0],tinyrect);
                
                Screen(w, 'FillRect', [0 0 0], leftrect);
                Screen(w, 'FillRect', [0 0 0], rightrect);
                Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                
                % draw bars
                Screen(w, 'FillRect', 255, [leftrect(1)+5 leftrect(2)+5+lefts(j) leftrect(3)-5 leftrect(4)-5]);
                Screen(w, 'FillRect', 255, [rightrect(1)+5 rightrect(2)+5+rights(j) rightrect(3)-5 rightrect(4)-5]);
                
                Screen(w,'Flip');
                
                % trigger presentation bars (= 10 - 19)
                if inEEG && EEG_trigger==1 && pr == 0
                    pport_mrk = 1;
                    pport_mrk = pport_mrk +8+j; %10-19
                    % trigger on
                    io32(pportObj, settings.pport.address, pport_mrk);
                    % wait as required by the amp
                    WaitSecs(settings.pport.int);
                    % trigger off
                    io32(pportObj, settings.pport.address, 0);
                    %give the trigger a numerical value
                    
                    EEG_trigger=0; % only trigger on first presentation
                    data.onset(t,j) = ceil((GetSecs-sstart).*1000); % get timing of trigger
                    data.baronset(t,j) = GetSecs - expstart; % get timing of bar
                    
                    WaitSecs(0.004); %changed this from 1, will it matter?
                end
                
                selapsed=ceil((GetSecs-sstart).*1000);

                % check whether eyes are within frame around fixation cross                
                if isTobii && pr==0;
                    % 3. Tobii Collect time stamp
                    dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                    if (any(mlDataNum(2:5) <= 0.4) || any(mlDataNum(2:5) >= 0.6)) && ~((mlDataNum(2) == 0 && mlDataNum(3) == 0) || (mlDataNum(4) == 0 && mlDataNum(5) == 0))
                        out_bounds = out_bounds + 1;
                    elseif mlDataNum(2:5) == 0
                        check_eyes = check_eyes + 1;
                    end
                end
                
            elseif selapsed>=data.randgap(t,j) + 350; % after ~500ms, go to next bar presentation
                
                selapsed=ceil((GetSecs-sstart).*1000);
                
                sstart=GetSecs; % reference for new bar
                pres(j)=1; % count presented bar
                j=j+1; % count presented bar
                
                Screen(w,'FillOval',[0 0 0],tinyrect);
                
                Screen(w, 'FillRect', [0 0 0], leftrect);
                Screen(w, 'FillRect', [0 0 0], rightrect);
                Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                %Screen(w,'FillRect',128);  % blank screen
                
                Screen(w,'Flip');
            end
        end
         
        % MASK after last bar
        Screen(w, 'FillRect', [0 0 0], leftrect);
        Screen(w, 'FillRect', [0 0 0], rightrect);
        
        Screen(w, 'FillRect', [50], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
        Screen(w, 'FillRect', [50], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
        Screen(w,'Flip');
        
        tstop = GetSecs; % timing of end of trial
        WaitSecs(0.05);
        
        %% Check responses
        
        Screen(w,'FillRect',128);  % blank screen
        Screen(w,'FillOval',[255 255 255],tinyrect);
        Screen(w,'Flip');
      
        % If you want to test the script, uncomment this        
%         RT=2;
%         keycode=Lft;%out;
%         resp=1;
        
        % avoid to register arrow keys (no clue why it should do it in the first place...)
        codes  = zeros(1,256); % Windows = 256, Mac = 128;

        while resp==0 || any(codes([37:40]) == 1) % ignore arrow key presses
            
            [kdown secs codes]=KbCheck;  % check for key press
            
            codes([37:40]) = 0; % avoid getting stuck in while loop
            
            % check escape key
            if kdown==1;
                if codes(Ext)==1;  % if escape key 27 in wind
                    
                    save('datatmp.mat', 'data');

                    disconnect_Tobii(isTobii,obj)
                    
                    Screen('CloseAll');
                    ShowCursor;
                    
                    break % exit experiment
                end
                
                % If a key is pressed and it's not escape                
                press=press+1; % count key press
                
                if codes(Lft)==1 || codes(Rgt)==1;
                    RT=GetSecs-tstop;  % log RT
                    keycode=find(codes==1);  % which button
                    keycode=keycode(1);  % take only first in case of simultaneous press
                    disp(['key  ',num2str(keycode),', ',num2str(RT),'ms']);    % write to command window
                    resp=1;
                    
                    % trigger left response (= 70)
                    if inEEG && keycode == Lft && pr == 0
                        pport_mrk = 1;
                        pport_mrk = pport_mrk + 69;
                        % trigger on
                        io32(pportObj, settings.pport.address, pport_mrk);
                        % wait as required by the amp
                        WaitSecs(settings.pport.int);
                        % trigger off
                        io32(pportObj, settings.pport.address, 0);
                        
                        data.responset(t) = GetSecs - expstart; % get RT considering the trigger
                        
                        %give the trigger a numerical value                        
                        WaitSecs(0.004); %changed this from 1, will it matter?

                    % trigger right response (= 71)
                    elseif inEEG && keycode == Rgt && pr == 0
                        pport_mrk = 1;
                        pport_mrk = pport_mrk + 70;
                        % trigger on
                        io32(pportObj, settings.pport.address, pport_mrk);
                        % wait as required by the amp
                        WaitSecs(settings.pport.int);
                        % trigger off
                        io32(pportObj, settings.pport.address, 0);
                        
                        data.responset(t) = GetSecs - expstart; % get RT considering the trigger
                        
                        %give the trigger a numerical value                        
                        WaitSecs(0.004); %changed this from 1, will it matter?
                    end              
                end
            end
        end
        
        % End of eye tracking epoch
        if isTobii && pr == 0;
            % 3. Tobii Collect time stamp
            dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
            data.timestampData(t,2) = mlDataNum(1);
        end
        
        selapsed=ceil((GetSecs-sstart).*1000);
        
        %% Feedback
        
        if selapsed>deadline % response was too late
            
            Screen('TextSize', w , 50 );
            Screen(w,'DrawText','Slow response!',(rect(3)/2)+100,(rect(4)/2)+50,[255 0 0]);   % draw instuctions
            Screen(w,'Flip');  % write to screen
            
            % EEG trigger for slow response (= 72) 
            % if this was not here, the amount of triggers would be different depending on how many time a participant was too slow
            if inEEG && pr == 0
                pport_mrk = 1;
                pport_mrk = pport_mrk + 71;
                % trigger on
                io32(pportObj, settings.pport.address, pport_mrk);
                % wait as required by the amp
                WaitSecs(settings.pport.int);
                % trigger off
                io32(pportObj, settings.pport.address, 0);
                
                data.responset(t) = GetSecs - expstart; % get RT considering the trigger
                
                %give the trigger a numerical value
                WaitSecs(0.004); %changed this from 1, will it matter?          
            end
            
            response=-1;
            RT=-99;
            WaitSecs(1);
           
        % if response was before deadline    
        else
            if keycode>0 
                
                if (SR == 1 && session == 1) || (SR == 0 && session == 2) % HIGH FRAME                   
                    if keycode==Lft %left
                        colf=[255 255 255]*0;                        
                        
                        if (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                            colf=[0 255 0]; % green
                        elseif (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                            colf=[255 0 0]; % red
                        end
                        
                        Screen(w,'FillOval',colf,tinyrect);
                        
                        response=pos(1); % is 1 (correct) for data.order = 0 and 2 (correct) for data.order = 1
                        disp([num2str(data.order(t)),':',num2str(response)]);
                        
                    elseif keycode==Rgt %right
                        colf=[255 255 255]*0;
                        
                        if (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                            colf=[0 255 0]; % green
                        elseif (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                            colf=[255 0 0]; % red
                        end
                        Screen(w,'FillOval',colf,tinyrect);
                        
                        response=pos(2);
                        disp([num2str(data.order(t)),':',num2str(response)]);
                        
                    elseif keycode==Ext
                        
                        save('datatmp.mat', 'data');
                        
                        Screen('CloseAll');
                        ShowCursor;
                        %send_email_db;
                        
                        % Disconnect everywhere!! Otherwise Tobii keeps logging
                        disconnect_Tobii(isTobii,obj)

                        break    % exit program
                    end
                    
                else % LOW FRAME                   
                    if keycode==Lft %left                        
                        Screen(w,'FillOval',[0 0 0],tinyrect);
                        
                        if (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                            colf=[255 0 0]; % red
                        elseif (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                            colf=[0 255 0]; % green
                        end
                        Screen(w,'FillOval',colf,tinyrect);
                        
                        response=pos(1);
                        disp([num2str(data.order(t)),':',num2str(response)]);
                        
                    elseif keycode==Rgt %right
                        colf=[255 255 255]*0;
                        
                        if (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                            colf=[255 0 0]; % red
                        elseif (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                            colf=[0 255 0]; % green
                        end
                        Screen(w,'FillOval',colf,tinyrect);

                        response=pos(2);
                        disp([num2str(data.order(t)),':',num2str(response)]);
                        
                    elseif keycode==Ext
 
                        Screen('CloseAll');
                        ShowCursor
                        save('datatmp.mat', 'data');
                        
                        disconnect_Tobii(isTobii,obj)

                        %send_email_db;
                        
                        break    % exit program
                    end
                end
                
                % Consequences of eyes moved too much
                if out_bounds > 30
                    disp('Eyes moved');
                    
                    eyes_moved = eyes_moved + 1; % if eye tracker freaks out, make feedback stop after a while
                    data.repeat_trials = [data.repeat_trials t];                    
                    
                    if eyes_moved < 60
                        
                        Screen('TextSize', w , 50 );
                        Screen(w,'DrawText','Eyes moved!',(rect(3)/2)+100,(rect(4)/2)+100,[0 0 0]);   % draw instuctions
                    end
                end
                
                Screen(w,'Flip');
                WaitSecs(wrate);
                
            end
        end
        
        %% Stuff that needs to be defined after a trial
        
        % show whether eyes aren't tracked anymore                
        if check_eyes > 10
            disp('No eye tracking this trial')
        end        
        
        % blank screen
        Screen(w,'FillRect',128);
        Screen(w,'FillOval',255,tinyrect);
        Screen(w,'Flip');
        WaitSecs(0.3);

        % log data
        data.keycode(t)=keycode;
        data.RT(t)=RT;
        data.response(t)=response;
        data.block(t)=bl;
        
        %% end of block
        if (mod(t,numtrials/10)==0 & pr==0)
            
            Screen(w,'FillRect',128);
            Screen(w,'DrawText','Block completed',(rect(3)/2),(rect(4)/2)+50,255);
            
            rewd=length(find(data.type<10 & data.response==1 & data.block==bl))./length(find(data.type<10 & data.block==bl));
            rewd=round(rewd*100)/100;
            Screen('TextSize', w , 50 );
            
            Screen('TextSize', w , 30 );
            Screen(w,'DrawText',['Block accuracy: ' num2str(100*rewd) '%'],(rect(3)/2)+30,(rect(4)/2)+200,[0 0 255]/4);
            Screen(w,'DrawText','Take a short break.',(rect(3)/2)+30,(rect(4)/2)+300,255);
            Screen(w,'DrawText','Press any key to continue...',(rect(3)/2)+30,(rect(4)/2)+400,255);   % draw instuctions
            Screen('TextSize', w ,20);
            Screen(w,'DrawText','Press C to calibrate again',(rect(3)/2)+30,(rect(4)/2)+480,255);          
            Screen('TextSize', w , 65 );
            Screen(w,'Flip');
   
            save('datatmp.mat', 'data');
            
            WaitSecs(1);
            
            % Check C key to do calibration again if wanted
            kdown = 0;
            while kdown == 0
                [kdown secs calkey] = KbCheck;
            end
            
            % do calibration again
            if isTobii && calkey(67) == 1
                
                data.calibration(bl) = 1;
                
                Screen('CloseAll');
                
                disconnect_Tobii(isTobii,obj)
                         
                [obj] = connect_Tobii(isTobii);
                
                % Get font size and screens back to previous settings
                [w, rect] = Screen('OpenWindow', scr_max, 0,[],32,2);
                Screen('TextFont', w, 'Calibri');
                Screen('TextSize', w , 50 );
                [wl,rect]=Screen('OpenOffscreenWindow', scr_max, 0, leftrect);
            end
        end
    end
    
    %% Run the extra block with trials where the eyes moved
    if pr == 0
        main_task_rep
    end

catch
    
    Screen('CloseAll');  % if error, then exit
    ShowCursor;
    save('datatmp.mat', 'data');
    clear io32
    
    if obj == 1
        disconnect_Tobii(isTobii,obj);
    end
    
    rethrow(lasterror);
    send_email_db;
end
toc

save('datatmp.mat', 'data');

%% End of experiment

if pr==0
    Screen('TextSize', w , 30 );
    Screen(w,'DrawText','You have now completed the experiment.',(rect(3)/2),(rect(4)/2)+50,255);
    Screen('TextSize', w , 30 );
    rewd=length(find(data.type~=0 & data.response==1))./length(find(data.type~=0));
    rewd=round(rewd*100)/100;
    Screen(w,'DrawText',['Overall accuracy: ' num2str(100*rewd) '%'],(rect(3)/2),(rect(4)/2)+150,[0 0 255]/4);
    Screen('TextSize', w , 30 );
    Screen(w,'DrawText','Please wait for the experimenter...',(rect(3)/2),(rect(4)/2)+250,255);   % draw instuctions
    
    Screen(w,'Flip');
    
    WaitSecs(1);KbWait;

    Screen('CloseAll');
    clear io32
    
    %Bonus
    data.rewd = rewd
    if data.rewd < 0.5
        data.bonus = 0
     elseif data.rewd < 0.6
        data.bonus = 5   
    elseif data.rewd < 0.85
        data.bonus = 10
    else 
        data.bonus = 15
    end
    
    disconnect_Tobii(isTobii,obj)
     
else % practice trials
    
    Screen(w,'FillRect',128);
    Screen('TextSize', w , 30 );
    Screen(w,'DrawText','End of practice.',(rect(3)/2)-100,(rect(4)/2)+50,0);
    Screen('TextSize', w , 30 );
    rewd=length(find(data.type~=0 & data.response==1))./length(find(data.type~=0));
    rewd=round(rewd*100)/100;
    Screen(w,'DrawText',['Overall accuracy: ' num2str(100*rewd) '%'],(rect(3)/2)-100,(rect(4)/2)+100,[0 0 255]/4);
    Screen(w,'DrawText','Please call the experimenter if you have any questions.',(rect(3)/2)+100,(rect(4)/2)-100,0);
    Screen('TextSize', w , 30 );
    Screen(w,'DrawText','Press any key to start the experiment...',(rect(3)/2)-100,(rect(4)/2)+250,255);   % draw instuctions
    Screen(w,'DrawText','The practice trials will shut',(rect(3)/2)-100,(rect(4)/2)+300,255);   % draw instuctions
    Screen(w,'DrawText','down and open the experiment.',(rect(3)/2)-100,(rect(4)/2)+350,255);   % draw instuctions
    
    
    Screen(w,'Flip');
    WaitSecs(1);KbWait;
    clear io32
    
    Screen('CloseAll');
    
    disconnect_Tobii(isTobii,obj)
    
end


end% bye bye


%% EEG triggers:

% fixation cross = 2
% Bars = 10 - 19
% response left = 70
% response right = 71
% no response = 72
% feedback correct = 30
% feedback incorrect = 31

%% FUNCTIONS

function [obj] = connect_Tobii(isTobii)

%% Start Tobii Calibration, begin logging after returning focus to matlab, then get log file name in matlab
% 0.
system('C:\Program Files (x86)\Tobii\Tobii EyeX\Tobii.EyeX.Settings.exe');
pause

%% Put this at the start of your matlab. It only want to be run once.
% 1. Tobii Initialize
dllPathname = fullfile('C:\Users\acclab\Documents\Tobii32','Tobii2Matlab32.dll'); %makes the path of wherever you put the .dll I sent you. Change the first argument to the path of the Tobii2Matlab.dll
asmInfo = NET.addAssembly(dllPathname); %This calls the .dll that I wrote that wraps the core functions in the tobii .net API
obj = Tobii2Matlab32.Class1; %Returns an object of the class (class1 should have a better name ... my bad)

% 2. Tobii Connect
connectedString = StartTobii(obj); %connect to tobii, and start logging
if (strcmp(char(connectedString),'Connected') == 0) %although this is fancy error catching, the .net will fail before this matlab catch activates
    error('Tobii did not connect'); %but it demonstrates how you can parse and process the data coming back from the tobii
else
    display('Tobii connected successfully');
end

end

function disconnect_Tobii(isTobii,obj)

if isTobii;
    % 4. Tobii Disconnect
    disconnectedString = StopTracking(obj); %disconnect from tobii and stop tracking
    if (strcmp(char(disconnectedString),'Disconnected') == 0) %although this is fancy error catching, the .net will fail before this matlab catch activates
        error('Tobii did not disconnect');
    else
        display('Tobii disconnected successfully');
    end
end

dbstop if error

end
