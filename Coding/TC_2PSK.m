% Simulator for TC: LDPC channel coding, 2-PSK modulation

clc
clear
close all
load 128_64_LDPCcode.mat

%% Simulation parameters
k=64;
n=128;
Eb_No=0:1:4;
Eb_No_linear=10.^(Eb_No./10);
sigma=sqrt(2*(k/n).*Eb_No_linear);
numMaxWrongRxCodewords=100;
numMaxIterNMS=100;
normValueNMS=0.8;
%% Values for Tanner graph
% Variable nodes: inspecting H by rows
for row=1:size(H,1)
    Tanner_v2c{row}=find(H(row,:));
end
% Check nodes: inspecting H by columns
for col=1:size(H,2)
    Tanner_c2v{col}=(find(H(:,col)))';
end

%% Monte-Carlo simulation
for energy=1:length(Eb_No)
    %% Initializations per energy point
    numTxCodewords=0;
    numTxInfoBits=0;
    numWrongRxCodewords=0;
    numWrongRxInfoBits=0;
    while numWrongRxCodewords<=numMaxWrongRxCodewords
        %% Information frame generation
        infoBits=randi([0 1],k,1)';
        % Update counters for Tx
        numTxCodewords=numTxCodewords+1;
        numTxInfoBits=numTxInfoBits+k;
        %% LDPC encoding
        codeword=mod(infoBits*G,2);
        %% 2-PSK modulation
        symbolTx=2*codeword-1;
        %% AWGN channel
        noise=sigma(energy)*randn(1,n);
        symbolRx=symbolTx+noise;
        %% LDPC decoding
        % Syndrone test
        y=symbolRx>=0;
        syndrone=mod(y*H',2);
        % Starting condition of the NMS iterative algorithm
        if sum(syndrone)~=0
            % Algorithm initialization
            LLR=2*symbolRx./(sigma(energy)^2);    % computed on received codeword
            nIterNMS=1;
            m=n-k;
            % Initialize Tanner graph messages
            aPosterioriProb=zeros(n,1);
            channelMessage=H.*LLR;
            while nIterNMS<=numMaxIterNMS
                % Check node update
                for check=1:m
                    % Accessing variable node values connected to m-th check node
                    v2cMessage=channelMessage(check,Tanner_v2c{check});
                    for t=1:length(v2cMessage)
                        SignMessage=sign(v2cMessage);
                        MagnitudeMessage=abs(v2cMessage);
                        % Done to exclude t-th value
                        SignMessage(t)=1;
                        MagnitudeMessage(t)=Inf;
                        c2vMessage(t)=prod(nonzeros(full(SignMessage)))*min(nonzeros(full(MagnitudeMessage)))*normValueNMS;
                    end
                    % Updating the check node values in the matrix
                    channelMessage(check,Tanner_v2c{check})=c2vMessage;
                end
                % Variable node update
                % A-posteriori computation
                for variable=1:n
                    % Accessing check node values connected to n-th variable node
                    c2vMessage=channelMessage(Tanner_c2v{variable},variable);
                    var=LLR(variable)+sum(c2vMessage);
                    v2cMessage=(var-c2vMessage)*normValueNMS;
                    % Updating the variable node values in the matrix
                    channelMessage(Tanner_c2v{variable},variable)=v2cMessage;
                    % Update a-posteriori probability the specific v_i
                    aPosterioriProb(variable)=var;
                end
                % Syndrone computation
                y=aPosterioriProb'>=0;
                syndrone=mod(y*H',2);
                nIterNMS=nIterNMS+1;
                if sum(syndrone)==0
                    break;
                end
            end
        end
        % At this point it's either decoding success or failure,
        % it depends on the y=codewordRx at this point
        %% Error Rate Computation
        if ~isequal(codeword,y)
            % Update counters for wrong Rx
            numWrongRxCodewords=numWrongRxCodewords+1;
            numWrongRxInfoBits=numWrongRxInfoBits+sum(xor(infoBits,y(1:64)));
        end
    end
    %% Evaluation of CER and BER
    CER(energy)=numWrongRxCodewords/numTxCodewords;
    BER(energy)=numWrongRxInfoBits/numTxInfoBits;
end
%% Plotting CER and BER performance
figure
semilogy(Eb_No,CER,'-ob','LineWidth',3),axis('tight'),grid on;
ylim([10^(-5) 10^0])
axx=xlabel('$E_b/N_o$');
set(axx,'Interpreter','Latex');
axy=ylabel('Codeword Error Rate');
set(axy,'Interpreter','Latex');
tit=title('LDPC code (128,64) - NMS iterative decoding');
set(tit,'Interpreter','Latex');
leg=legend('CER');
set(leg,'Interpreter','Latex');
figure
semilogy(Eb_No,BER,'-sr','LineWidth',3),axis('tight'),grid on;
ylim([10^(-6) 10^0]);
axx=xlabel('$E_b/N_o$');
set(axx,'Interpreter','Latex');
axy=ylabel('Bit Error Rate');
set(axy,'Interpreter','Latex');
tit=title('LDPC code (128,64) - NMS iterative decoding');
set(tit,'Interpreter','Latex');
leg=legend('BER');
set(leg,'Interpreter','Latex');