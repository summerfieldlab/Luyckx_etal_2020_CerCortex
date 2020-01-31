 
 
clear all;
close all;
addpath('functions/');
KbName('UnifyKeyNames');
% create participant structure
argindlg = inputdlg({'Computer Id','Session','Gender (M/F)','Age','Hand (L/R)'},'',1,{'000','0','','','R'});
if isempty(argindlg)
    participant.name = 'NULL';
    %participant.number = 999;
else
    participant = struct;
    participant.name = upper(argindlg{1});
    participant.session = argindlg{2};
    participant.gender = argindlg{3};
    participant.age  = argindlg{4};
    participant.handedness = argindlg{5};
end

type=1;
participant.filename = sprintf('Barexp_EEG_%s_3%s_sess_%s.mat',participant.name,datestr(now,'yyyymmddHHMMSS'),participant.session);
participant.filename_p = sprintf('Barexp_EEG_%s_pract_%s_sess_%s.mat',participant.name,datestr(now,'yyyymmddHHMMSS'),participant.session);

% determine framing
sub = str2num(participant.name);
session = str2num(participant.session);
SR = rem(sub,2);    % first session low frame = even, high frame = odd  

%  training and instructions
pract = generate_pract(40);
[prac_resp]=main_task(pract,1,SR,session);
save(participant.filename_p,'pract','prac_resp','participant');

%% actual experiment
data=generate_input(600); 
[data_resp]=main_task(data,0,SR,session);
save(participant.filename,'data','data_resp','participant');

%disp(['Bonus=%',num2str(data_resp.rewd)]);

send_email_db;
