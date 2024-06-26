clear all
close all
clc

% %veriler y�kleniyor
% load RegressionData.mat

z(1) = 0.1;
for i=1:1056
    z(i+1) = 3.9*z(i)*[1-z(i)]; %kaotik sistemin fark denklemi
end

R = 5;
T = [] ; Y = [];
for i=1:length(z)-R
    T = [T; z(i:R+i-1)];
    Y = [Y; z(R+i)];
end

[N,R] = size(T);
TrainingIndex   = 1:2:N;
ValidationIndex = 2:2:N;

TrainingINPUT = T(TrainingIndex,:);
TrainingOUTPUT = Y(TrainingIndex,:);
ValidationINPUT = T(ValidationIndex,:);
ValidationOUTPUT = Y(ValidationIndex,:);

Ntraining = size(TrainingINPUT,1);
Nvalidation = size(ValidationINPUT,1);

S = 3;  %yapay sinir a� say�s�

if S*(R+2)+1>Ntraining
    disp('too many parameters!')
end
Nmax = 100;

Wg = rand(S,R)-0.5;  %-0,5 aras�nda matris
bh = rand(S,1)-0.5;
Wc = rand(1,S)-0.5;
bc = rand(1,1)-0.5;

I = eye(S*(R+2)+1);

kosul = 1; iteration = 0;  mu = 1; FvalMIN = inf;
while kosul
    iteration = iteration+1;
    [yhat] = MISOYSAmodel2(TrainingINPUT,Wg,bh,Wc,bc);
    eTRA = TrainingOUTPUT-yhat;  %hata say�s�
    f = eTRA'*eTRA;  %performans
    J = [];
    
    for i=1:Ntraining
        for j=S*(R+2)+1
            J(i,j) = -1;
        end
        for j=S*(R+1)+1:S*(R+1)+S
            J(i,j) = -tanh(Wg(j-S*(R+1),:)*TrainingINPUT(i,:)'+bh(j-(R+1)*S));
        end
        for j=S*R+1:S*R+S
            J(i,j) = -Wc(1,j-S*R)*(1)*[1-tanh(Wg(j-S*R,:)*TrainingINPUT(i,:)'+bh(j-S*R))^2] ;
        end
        for j=1:S*R
            k = mod(j-1,S)+1;
            m = fix((j-1)/S)+1;
            J(i,j) = -Wc(1,k)*TrainingINPUT(i,m)*[1-tanh(Wg(k,:)*TrainingINPUT(i,:)'+bh(k))^2];
        end
    end
    
    loop2 = 1;
    while loop2
        p = -inv(J'*J+mu*I)*J'*eTRA;
        [x]=matrix2vector2(Wg,bh,Wc,bc);
        [Wgz,bhz,Wcz,bcz]=vector2matrix2(x+p,S,R);
        [yhat]=MISOYSAmodel2(TrainingINPUT,Wgz,bhz,Wcz,bcz);
        fz = (TrainingOUTPUT-yhat)'*(TrainingOUTPUT-yhat);
        
        if fz<f
            x = x + p;
            [Wg,bh,Wc,bc]=vector2matrix2(x,S,R);
            mu = 0.1*mu; %h�z� art�r
            loop2 = 0;
        else
            mu = mu*10;  %h�z� azalt
            if mu>1e+20; loop2=0 ; kosul=0; end
        end
    end
    [yhat] = MISOYSAmodel2(TrainingINPUT,Wg,bh,Wc,bc);
    eTRA = TrainingOUTPUT-yhat;
    f = eTRA'*eTRA;
    FTRAINING(iteration) = f;
    
    [yhat] =MISOYSAmodel2(ValidationINPUT,Wg,bh,Wc,bc);
    eVAL = ValidationOUTPUT-yhat;
    fVALIDATION = eVAL'*eVAL;
    FVALIDATION(iteration) = fVALIDATION;
    if fVALIDATION<FvalMIN  %Her ad�mda en iyi val'i sakl�yor
        xbest = x;  %En iyi x de�eri xbest'e kaydoluyor
        FvalMIN = fVALIDATION;
    end
    
    g = 2*J'*eTRA;
    fprintf('k:%4.0f\t ||g||: %4.6f\t ft: %4.6f\t fv: %4.6f\n',([iteration norm(g) FvalMIN fVALIDATION]))
    if [iteration>=Nmax] ; kosul = 0; end
end

[Wg,bh,Wc,bc] = vector2matrix2(xbest,S,R);
[yhatTR] = MISOYSAmodel2(TrainingINPUT,Wg,bh,Wc,bc);
[yhatVA] = MISOYSAmodel2(ValidationINPUT,Wg,bh,Wc,bc);

subplot(211)
plot(TrainingIndex,TrainingOUTPUT,'r.')
hold on
plot(ValidationIndex,ValidationOUTPUT,'g.')
plot(TrainingIndex,yhatTR,'b.')
plot(ValidationIndex,yhatVA,'b.')

subplot(212)
plot(FTRAINING,'b')
hold on
plot(FVALIDATION,'r')
title(['S:', num2str(S), '  Fvalbest=', num2str(FvalMIN)])

