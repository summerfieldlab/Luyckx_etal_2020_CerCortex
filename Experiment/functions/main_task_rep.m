
try
    
    
    bl=bl+1;
    rews=[];
    Screen(w,'FillPoly',[0 255 0],[100 100; 200 200; 300 300;]);
    
    Screen(w,'FillRect',128);
    Screen(w,'DrawText',['Block 11'],(rect(3)/2),(rect(4)/2)+50,0);
    
    Screen('TextSize', w , 30 );
    Screen(w,'DrawText','Press any key to continue...',(rect(3)/2)+100,(rect(4)/2)+250,255);   % draw instuctions
    Screen('TextSize', w , 65 );
    Screen(w,'Flip');
    WaitSecs(1);KbWait;
    
    Screen(w,'FillRect',128);
    Screen(w,'Flip');
    WaitSecs(1);
     
    %% Presentation
    
    for t=data.repeat_trials;  % loop through missed trials
        
        extra_t = extra_t + 1;
        ind = numtrials + extra_t;
        disp(num2str(ind));
        
        side=data.side(t);
        
            % encode differently for high and low frame, so response = 1 still means 'correct'
            if SR == 1 % HIGH FRAME
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
            
            Screen(w,'FillRect',128);
            Screen(w,'FillOval',255,tinyrect);
            Screen(w,'Flip');
            
            % trigger fixation cross
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
                
                WaitSecs(0.004); %changed this from 1, will it matter?
            end
            
            if isTobii && pr==0;
                % 3. Tobii Collect time stamp
                dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                data.timestampData(ind,1) = mlDataNum(1);
                %disp('epoch go')
            end
            
            WaitSecs(.3);
            
            % on each trial
            h=GetSecs;
            seq=size(data.left,2);
            
            %% Present
            tstart=GetSecs;
            sstart=GetSecs;
            time1=GetSecs;
            j=1;
            resp = 0;
            pres = zeros(1,length(lefts));
            press = 0;
            keycode=0;
            cor=0;
            out_bounds = 0;
            
            %MASK
            for j=1:1;
                
                count=0;
                Screen(w, 'FillRect', [0 0 0], leftrect);
                Screen(w, 'FillRect', [0 0 0], rightrect);
                
                Screen(w, 'FillRect', [50], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                Screen(w, 'FillRect', [50], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                Screen(w,'Flip');
                WaitSecs(0.05);
                
            end
            
            %% presentation with EEG, normal way
            while j<=durs(1);
                
                selapsed=ceil((GetSecs-sstart).*1000);
                
                if selapsed<data.randgap(t,j)
                    
                    %Screen(w,'FillRect',128);  % blank screen
                    Screen(w,'FillOval',[0 0 0],tinyrect);
                    
                    Screen(w, 'FillRect', [0 0 0], leftrect);
                    Screen(w, 'FillRect', [0 0 0], rightrect);
                    
                    Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                    Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                    Screen(w,'Flip');
                    
                    EEG_trigger=1;
                    
                    if isTobii && pr==0;
                        % 3. Tobii Collect time stamp
                        dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                        if (any(mlDataNum(2:5) <= 0.4) || any(mlDataNum(2:5) >= 0.6)) && ~((mlDataNum(2) == 0 && mlDataNum(3) == 0) || (mlDataNum(4) == 0 && mlDataNum(5) == 0))
                            out_bounds = out_bounds + 1;
                        elseif mlDataNum(2:5) == 0
                            check_eyes = check_eyes + 1;
                        end
                    end
                    
                    selapsed=ceil((GetSecs-sstart).*1000);
                    
                elseif selapsed>=data.randgap(t,j) && selapsed<data.randgap(t,j) + 350;
                    
                    Screen(w,'FillOval',[0 0 0],tinyrect);
                    
                    Screen(w, 'FillRect', [0 0 0], leftrect);
                    Screen(w, 'FillRect', [0 0 0], rightrect);
                    Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                    Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                    
                    % draw bars
                    Screen(w, 'FillRect', 255, [leftrect(1)+5 leftrect(2)+5+lefts(j) leftrect(3)-5 leftrect(4)-5]);
                    Screen(w, 'FillRect', 255, [rightrect(1)+5 rightrect(2)+5+rights(j) rightrect(3)-5 rightrect(4)-5]);
                    
                    Screen(w,'Flip');
                    
                    % trigger presentation bars
                    if inEEG && EEG_trigger==1 && pr == 0
                        pport_mrk = 1;
                        pport_mrk = pport_mrk +8+j; %10-22
                        % trigger on
                        io32(pportObj, settings.pport.address, pport_mrk);
                        % wait as required by the amp
                        WaitSecs(settings.pport.int);
                        % trigger off
                        io32(pportObj, settings.pport.address, 0);
                        %give the trigger a numerical value
                        
                        EEG_trigger=0;
                        data.onset(ind,j) = ceil((GetSecs-sstart).*1000);
                        data.baronset(ind,j) = GetSecs - expstart;
                        WaitSecs(0.004); %changed this from 1, will it matter?
                    end
                    
                    if isTobii && pr==0;
                        % 3. Tobii Collect time stamp
                        dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                        if (any(mlDataNum(2:5) <= 0.4) || any(mlDataNum(2:5) >= 0.6)) && ~((mlDataNum(2) == 0 && mlDataNum(3) == 0) || (mlDataNum(4) == 0 && mlDataNum(5) == 0))
                            out_bounds = out_bounds + 1;
                        elseif mlDataNum(2:5) == 0
                            check_eyes = check_eyes + 1;
                        end
                    end
                    
                    selapsed=ceil((GetSecs-sstart).*1000);
                    
                elseif selapsed>=data.randgap(t,j) + 350;
                    
                    selapsed=ceil((GetSecs-sstart).*1000);
                    
                    sstart=GetSecs;
                    pres(j)=1;
                    j=j+1;
                    
                    Screen(w,'FillOval',[0 0 0],tinyrect);
                    
                    Screen(w, 'FillRect', [0 0 0], leftrect);
                    Screen(w, 'FillRect', [0 0 0], rightrect);
                    Screen(w, 'FillRect', [128], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
                    Screen(w, 'FillRect', [128], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
                    %Screen(w,'FillRect',128);  % blank screen
                    
                    Screen(w,'Flip');
                end
            end
            
            %%MASK
            Screen(w, 'FillRect', [0 0 0], leftrect);
            Screen(w, 'FillRect', [0 0 0], rightrect);
            
            Screen(w, 'FillRect', [50], [leftrect(1)+5 leftrect(2)+5 leftrect(3)-5 leftrect(4)-5]);
            Screen(w, 'FillRect', [50], [rightrect(1)+5 rightrect(2)+5 rightrect(3)-5 rightrect(4)-5]);
            Screen(w,'Flip');
            
            tstop = GetSecs;
            WaitSecs(0.05);
            
            %%
            
            Screen(w,'FillRect',128);  % blank screen
            Screen(w,'FillOval',[255 255 255],tinyrect);
            Screen(w,'Flip');
            
            %% store responses
            %         RT=2;
            %         keycode=Lft;%out;
            %         resp=1;
            
            while resp==0
                [kdown secs codes]=KbCheck;  % check for key press
                [x y buttons]=GetMouse;      % check for mouse press
                
                % check escape key
                if kdown==1;
                    if codes(Ext)==1;  % if escape key 27 in wind
                        
                        save('datatmp.mat', 'data');
                        Screen('CloseAll');
                        ShowCursor;
 
                        disconnect_Tobii(isTobii,obj)

                        break % exit experiment
                    end
                    
                    press=press+1;
                    if codes(Lft)==1 || codes(Rgt)==1;
                        RT=GetSecs-tstop;  % log RT
                        keycode=find(codes==1);  % which button
                        keycode=keycode(1);  % take only first in case of simultaneous press
                        disp(['key  ',num2str(keycode),', ',num2str(RT),'ms']);    % write to command window
                        resp=1;
                        
                        % trigger left response
                        if inEEG && keycode == Lft && pr == 0
                            pport_mrk = 1;
                            pport_mrk = pport_mrk + 69;
                            % trigger on
                            io32(pportObj, settings.pport.address, pport_mrk);
                            % wait as required by the amp
                            WaitSecs(settings.pport.int);
                            % trigger off
                            io32(pportObj, settings.pport.address, 0);
                            
                            data.responset(ind) = GetSecs - expstart;
                            
                            %give the trigger a numerical value
                            WaitSecs(0.004); %changed this from 1, will it matter?
                            
                            % trigger right response
                        elseif inEEG && keycode == Rgt && pr == 0
                            pport_mrk = 1;
                            pport_mrk = pport_mrk + 70;
                            % trigger on
                            io32(pportObj, settings.pport.address, pport_mrk);
                            % wait as required by the amp
                            WaitSecs(settings.pport.int);
                            % trigger off
                            io32(pportObj, settings.pport.address, 0);
                            
                            data.responset(ind) = GetSecs - expstart;
                            
                            %give the trigger a numerical value
                            WaitSecs(0.004); %changed this from 1, will it matter?
                        end
                        
                    end
                end
            end
            
            if isTobii && pr == 0;
                % 3. Tobii Collect time stamp
                dataString = EyeTrackerGazeData2Matlab(obj); mlDataString = char(dataString); C = strsplit(mlDataString); mlDataNum = str2double(C);
                data.timestampData(ind,2) = mlDataNum(1);
                %disp('epoch end')
            end
            
            selapsed=ceil((GetSecs-sstart).*1000);
            
            % feedback
            if selapsed>deadline
                Screen('TextSize', w , 50 );
                Screen(w,'DrawText','Slow response!',(rect(3)/2)+100,(rect(4)/2)+50,[255 0 0]);   % draw instuctions
                Screen(w,'Flip');  % write to screen
                
                if inEEG && pr == 0
                    pport_mrk = 1;
                    pport_mrk = pport_mrk + 71;
                    % trigger on
                    io32(pportObj, settings.pport.address, pport_mrk);
                    % wait as required by the amp
                    WaitSecs(settings.pport.int);
                    % trigger off
                    io32(pportObj, settings.pport.address, 0);
                    
                    data.responset(ind) = GetSecs - expstart;
                    
                    %give the trigger a numerical value
                    WaitSecs(0.004); %changed this from 1, will it matter?
                end
                
                response=-1;
                RT=-99;
                WaitSecs(1);
            else
                if keycode>0
                    
                    if SR == 1 % HIGH FRAME
                        if keycode==Lft %left
                            colf=[255 255 255]*0;
                            
                            Screen(w,'FillOval',[0 0 0],tinyrect);
                            if (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                                colf=[0 255 0];
                            elseif (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                                colf=[255 0 0];
                            end
                            Screen(w,'FillOval',colf,tinyrect);
                            
                            response=pos(1); % is 1 (correct) for data.order = 0 and 2 (correct) for data.order = 1
                            disp([num2str(data.order(t)),':',num2str(response)]);
                            
                        elseif keycode==Rgt %right
                            colf=[255 255 255]*0;
                            
                            if (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                                colf=[0 255 0];
                            elseif (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                                colf=[255 0 0];
                            end
                            Screen(w,'FillOval',colf,tinyrect);
                            
                            response=pos(2);
                            disp([num2str(data.order(t)),':',num2str(response)]);
                            
                        elseif keycode==Ext

                            save('datatmp.mat', 'data');
                            
                            Screen('CloseAll');
                            ShowCursor;
                            %send_email_db;
                            
                            disconnect_Tobii(isTobii,obj)
                            
                            break    % exit program
                        end
                        
                    else % LOW FRAME
                        if keycode==Lft %left
                            colf=[255 255 255]*0;
                            
                            Screen(w,'FillOval',[0 0 0],tinyrect);
                            if (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                                colf=[255 0 0];
                            elseif (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                                colf=[0 255 0];
                            end
                            Screen(w,'FillOval',colf,tinyrect);
                            
                            response=pos(1);
                            disp([num2str(data.order(t)),':',num2str(response)]);
                            
                        elseif keycode==Rgt %right
                            colf=[255 255 255]*0;
                            
                            if (data.order(t)==1 & pr==1) | (pr==0 & data.order(t)==1 & data.type(t)<10);
                                colf=[255 0 0];
                            elseif (data.order(t)==0 & pr==1) | (pr==0 & data.order(t)==0 & data.type(t)<10);
                                colf=[0 255 0];
                            end
                            Screen(w,'FillOval',colf,tinyrect);
                            
                            response=pos(2);
                            disp([num2str(data.order(t)),':',num2str(response)]);
                            
                        elseif keycode==Ext
                            
                            if isTobii;
                                % 4. Tobii Disconnect
                                disconnectedString = StopTracking(obj); %disconnect from tobii and stop tracking
                                if (strcmp(char(disconnectedString),'Disconnected') == 0) %although this is fancy error catching, the .net will fail before this matlab catch activates
                                    error('Tobii did not disconnect');
                                else
                                    display('Tobii disconnected successfully');
                                end
                            end
                            
                            save('datatmp.mat', 'data');
                            
                            Screen('CloseAll');
                            ShowCursor
                            %send_email_db;
                            
                            break    % exit program
                        end
                    end
                    
                    if out_bounds > 30
                        
                        data.repeat_trials = [data.repeat_trials numtrials+extra_t];
                        
                        Screen('TextSize', w , 50 );
                        Screen(w,'DrawText','Eyes moved!',(rect(3)/2)+100,(rect(4)/2)+100,[0 0 0]);   % draw instuctions
                        
                    end
                    
                    Screen(w,'Flip');
                    WaitSecs(wrate);
                    
                end
            end
            
            %%
            
            % show whether eyes aren't tracked anymore
            if check_eyes > 10
                disp('No eye tracking this trial');
            end
            
            % blank screen for X s
            Screen(w,'FillRect',128);
            Screen(w,'FillOval',255,tinyrect);
            Screen(w,'Flip');
            WaitSecs(0.3);
            
            % log data            
            data.left(ind,:) = data.left(t,:);
            data.right(ind,:) = data.right(t,:);
            data.seq(ind) = data.seq(t);
            data.mean(ind) = data.mean(t);
            data.type(ind) = data.type(t);
            data.trial(ind) = data.trial(t);
            data.randgap(ind,:) = data.randgap(t,:);
            data.Lm(ind) = data.Lm(t);
            data.Rm(ind) = data.Rm(t);
            data.Lv(ind) = data.Lv(t);
            data.Rv(ind) = data.Rv(t);
            data.bases(ind,:) = data.bases(t,:);
            data.difs(ind,:) = data.difs(t,:);
            data.order(ind) = data.order(t);
            data.side(ind) = data.side(t);
            data.dd(ind) = data.dd(t);
            
            data.keycode(ind)=keycode;
            data.RT(ind)=RT;
            data.response(ind)=response;
            data.block(ind)=bl;
                    
        %% end of block
        if t == data.repeat_trials(end)
            Screen(w,'FillRect',128);
            Screen(w,'DrawText','Block 11 completed',(rect(3)/2),(rect(4)/2)+50,255);
            
            rewd=length(find(data.type<10 & data.response==1 & data.block==bl))./length(find(data.type<10 & data.block==bl));
            rewd=round(rewd*100)/100;
            
            Screen(w,'DrawText','Press any key to continue...',(rect(3)/2)+30,(rect(4)/2)+400,255);   % draw instuctions
            Screen('TextSize', w , 65 );
            Screen(w,'Flip');
            
            save('datatmp.mat', 'data');
            
            WaitSecs(1);KbWait;
        end
    end
    
catch
    
    Screen('CloseAll');  % if error, then exit
    ShowCursor;
    rethrow(lasterror);
    save('datatmp.mat', 'data');
    
    disconnect_Tobii(isTobii,obj)
    
    send_email_db;
end
