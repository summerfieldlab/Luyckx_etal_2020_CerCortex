function [ data ] = generate_input(notrials)

rand('state',sum(100*clock)); % init rand seed

lengths=[9];
%notrials = 20;
noblocks=10;
TrialsPerBlock = notrials/noblocks;

 
perms=[1    2   3
    1   3   2
    2   1   3
    2   3   1
    3   2   1
    3   1   2];

 
pairing=[1  2
    2   3
    3   1
    3   2
    2   1
    1   3];

 
sed=randi(6);
sf=[1 1];
colf=perms(sed,:);
D=20;
ofs=[0 0 +8 -8];

 
data.left=zeros(notrials,9);
data.right=data.left;
data.seq=[ones(1,notrials/4)];
data.seq=[data.seq data.seq data.seq data.seq];
data.mean=40+rand(1,notrials)*20;
vars=[10 10;20 20];
sz=notrials/4;
dd=[80+rand(1,sz)*40 80+rand(1,sz)*40 70+rand(1,sz)*20 70+rand(1,sz)*20];
data.type=repmat(1:4,1,notrials/4);
 
%% 

 
for i=1:notrials;
    
    
    ll=lengths(1);
    
    
    data.trial(i,:)=0;
    data.randgap(i,:) = 100 + randi(100,[1,9]);
    
    if data.type(i)<3
           
        data.Lm(i)=dd(i);
        data.Rm(i)=dd(i)+6;
        data.Lv(i)=vars(data.type(i),1);
        data.Rv(i)=vars(data.type(i),2);
        data.left(i,1:ll)=mypseudorandrange(data.Lm(i),data.Lv(i),ll,3,3,[0 200],1);
        data.right(i,1:ll)=mypseudorandrange(data.Rm(i),data.Rv(i),ll,3,3,[0 200],1);
   
    else
 
        data.Lm(i)=dd(i);
        data.Rm(i)=dd(i)+6;
        data.Lv(i)=0;
        data.Rv(i)=0;
        data.bases(i,1:ll/3)=mypseudorandrange(dd(i),4,ll/3,2,2,[20 180],1);

        
        if data.type(i)==3
            df=15+rand(1,3)*10;
            data.difs(i,1:ll/3)=[df];
            A=[];
            B=[];
            for j=1:ll/3
                kkk=randn*3;
                lll=randn*3;
                b=data.bases(i,j);
                difsA=[0+kkk data.difs(i,j)+lll 2*data.difs(i,j)-(kkk+lll)];
                difsB=[data.difs(i,j) 2*data.difs(i,j) 0];

                
                for k=1:3
                    A=[A b+difsA(k)];
                    B=[B b+difsB(k)];

                    
                end
            end
            sd=[randperm(ll/3) (ll/3)+randperm(ll/3) 2*(ll/3)+randperm(ll/3)];
            A=A(sd);B=B(sd);%C=C(sd);
            data.left(i,1:ll)=A;
            data.right(i,1:ll)=B+6;

            
        elseif data.type(i)==4
            df=15+rand(1,3)*10;
            data.difs(i,1:ll/3)=[df];

            
            A=[];
            B=[];

            
            for j=1:ll/3
                kkk=randn*3;
                lll=randn*3;
                b=data.bases(i,j);
                difsA=[0+kkk data.difs(i,j)+lll 2*data.difs(i,j)-(kkk+lll)];
                difsB=[data.difs(i,j) 2*data.difs(i,j) 0];

                
                for k=1:3
                    A=[A b+difsA(k)];
                    B=[B b+difsB(k)];

                    
                end
            end
            sd=[randperm(ll/3) (ll/3)+randperm(ll/3) 2*(ll/3)+randperm(ll/3)];
            A=A(sd);B=B(sd);%C=C(sd);
            data.left(i,1:ll)=B;
            data.right(i,1:ll)=A+6;

            
        end
    end
end

%% randomise and save
data.order=double(rand(1,length(data.left))>0.5);
data.side=sign(randn(1,length(data.left)));
data.dd=dd;

 
%% randomise conditions over blocks

blockvar=[];
bperm=randperm(noblocks);
for bv = 1:noblocks
    blockvar = [blockvar repmat(bperm(bv),1,TrialsPerBlock)]; % scramble block indices
end

 
blockperm=[];
for bp = 1:noblocks
    blockperm = [blockperm find(blockvar==bp)]; % scramble over blocks based on indices
end

data.left=data.left(blockperm,:);
data.dd=(data.dd(blockperm));
data.right=data.right(blockperm,:);
data.Lm=data.Lm(blockperm);
data.Rm=data.Rm(blockperm);
data.Lv=data.Lv(blockperm);
data.Rv=data.Rv(blockperm);
data.mean=data.mean(blockperm);
data.order=data.order(blockperm);
data.block=0*data.mean;
data.sed=sed;
data.type=data.type(blockperm);
data.randgap=data.randgap(blockperm,:);

 
%% randomise conditions within blocks

trialperm=[];
j=0;
for t = 1:noblocks
    trialperm = [trialperm randperm(TrialsPerBlock)+(j*TrialsPerBlock)];
    j=j+1;
end

data.left=data.left(trialperm,:);
data.dd=(data.dd(trialperm));
data.right=data.right(trialperm,:);
data.Lm=data.Lm(trialperm)';
data.Rm=data.Rm(trialperm)';
data.Lv=data.Lv(trialperm)';
data.Rv=data.Rv(trialperm)';
data.mean=data.mean(trialperm)';
data.order=data.order(trialperm)';
data.block=0*data.mean;
data.sed=sed;
data.type=data.type(trialperm)';
data.randgap=data.randgap(trialperm,:);
data.response=data.type*0;
data.bonus=0;
data.calibration = zeros(1,length(data.block)+1);

%%

% new = [data.type blockvar' trialperm']
% new(find(data.type==1),:)
% new(find(data.type==2),:)
% new(find(data.type==3),:)
% new(find(data.type==4),:)
% new(find(data.type==5),:)
% new(find(data.type==6),:)
%
% %Test distribution of wins in a trial
% for t=1:notrials
%     
%     comp = [];
%     for i=1:9
%         comp = [comp; data.left(t,i) data.right(t,i)];
%     end
%     
%     for x=1:9
%         if comp(x,1) < comp(x,2)
%             win(x) = 1;
%         else
%             win(x) = 0;
%         end
%     end
%     
%     checker(t,:) = [data.type(t) mean(win)];
%     
% end
% 
% checker(find(checker(:,1)==3),:)
% checker(find(checker(:,1)==4),:)