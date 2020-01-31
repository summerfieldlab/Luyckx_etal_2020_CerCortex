myaddress = '';
mypassword = '';

setpref('Internet','E_mail',myaddress);
setpref('Internet','SMTP_Server','smtp.gmail.com');
setpref('Internet','SMTP_Username',myaddress);
setpref('Internet','SMTP_Password',mypassword);

props = java.lang.System.getProperties;
props.setProperty('mail.smtp.auth','true');
props.setProperty('mail.smtp.socketFactory.class', ...
                  'javax.net.ssl.SSLSocketFactory');
props.setProperty('mail.smtp.socketFactory.port','465');

mf=dir('*Barexp_EEG*.mat');
mg=dir('*pract*.mat');
resultFileName1=mf(1).name;
resultFileName2=mg(1).name;
sendmail('', resultFileName1, 'data attached',{resultFileName1,resultFileName2});
