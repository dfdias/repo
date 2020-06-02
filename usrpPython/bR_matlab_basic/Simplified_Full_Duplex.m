 %% Carolina Gouveia - 21 de Fevereiro de 2020
% Bio-Radar em MATLAB (vers�o simplificada)
% Algoritmo de pos-processamento implementado em offline

clear all;
clc;
close all;
%%
% Escolha dos modos de execu��o do script:
% 1- Modo TXRX: Executar em modo Full_Duplex para adquirir um novo sinal
% 2- Modo Memory: Vai buscar sinais adquiridos previamente para se perceber o que deve resultar do pos-processamento
%   2.1 - Ry_b210_POtimo - Um sinal respirat�rio num ponto �timo
%   2.2 - Ry_b210_new - Um sinal respirat�rio num ponto n�o �timo (com ru�do)
% Nota: ambos os sinais foram adquiridos com 100kHz de frequ�ncia de
% amostragem e T = 100;

%% 0 - Escolher qual o modo para executar o script
md_TXRX = 0;                % Executar em modo TXRX
md_memory = 1;              % Executar em modo mem�ria 

if md_TXRX
    %% 1 - Encontrar e identificar o HW que est� a ser utilizado
    usrp_dev= findsdru();
    if strcmp(usrp_dev.Status, 'Success'),
        disp(['USRP ' usrp_dev.Platform ' detected'])
    else
        disp(['USRP not detected'])
    end
    
    %% 2 - Criar uma SINUSOIDE para ser transmitida
    % Defini��o de parametros da sinusoide gerada
    toneFreq = 10e3;                % Frequencia da sinusoide
    toneAmp = 1;                    % Amplitude da sinusoide
    toneSamples = 1000;             % Nr samples por frame
    toneComplexOut = true;          % O sinal gerado � um sinal complexo
    toneSampRate = 100e3;           % Frequencia de amostragem da sinusoide
    toneOutDataType = 'double';
    
    % Constru��o do objecto SineWave
    hSineSource = dsp.SineWave (...
        'Frequency',           toneFreq, ...
        'Amplitude',           toneAmp,...
        'ComplexOutput',       toneComplexOut, ...
        'SampleRate',          toneSampRate, ...
        'SamplesPerFrame',     toneSamples, ...
        'OutputDataType',      toneOutDataType)
    
    %% 3 - Defini��o dos parametros do front-end para a defini��o do objecto Rx e TX
    fcenter = 5.8e9;                            % Frequencia Portadora
    txgain = 70;                                % Ganho do transmissor
    rxgain = 70;                                % Ganho receptor
    MasterClockRate = 50e6;                     % Sampling rate
    toneSamples = 1000;                         % Nr de samples adquiridas em cada itera��o (nr samples por frame)
    L = MasterClockRate/toneSampRate;           % Factor de Interpola��o
    D = L;                                      % Factor de Decima��o
    Ch_nr = 1;                                  % Qual o canal do USRP que estamos a usar (caso seja USRP B210)
    
    %% 4 - Constru��o do objecto SDR Rx (configura��o do front-end para RECEP��O)
    disp('Setting parameters for the reception channel...')
    rx_SDRu = comm.SDRuReceiver(...
        'Platform',usrp_dev.Platform,...
        'SerialNum',usrp_dev.SerialNum,...
        'ChannelMapping', Ch_nr, ...
        'CenterFrequency',fcenter,...
        'Gain',rxgain,...
        'MasterClockRate', MasterClockRate,...
        'SamplesPerFrame', toneSamples,...
        'DecimationFactor', D,...
        'EnableBurstMode', false,...
        'TransportDataType', 'int16',...
        'OutputDataType', 'double');
    
    disp('Reception channel parameters set!')
    
    %% 5 - Constru��o do objecto SDR Tx (configura��o do front-end para TRANSMISS�O)
    disp('Setting parameters for the transmission channel...')
    
    tx_SDRu = comm.SDRuTransmitter(...
        'Platform',usrp_dev.Platform,...
        'SerialNum',usrp_dev.SerialNum,...
        'ChannelMapping', Ch_nr, ...
        'CenterFrequency',fcenter,...
        'Gain',txgain,...
        'MasterClockRate', MasterClockRate,...
        'InterpolationFactor', L,...
        'EnableBurstMode', false,...
        'TransportDataType', 'int16');
    
    disp('Transmission channel parameters set!')
    
    %% 6 - Defini��o de par�metros para o LOOP para TX e RX
    
    T = 100;                                      % Dura��o do processo de transmissao (segundos)
    Nframes = toneSampRate*T/toneSamples;        % Nr Total de Frames Transmitidas
    Nr = round(Nframes);                         % Arredonda o nr frames para inteiro
    Rt = zeros(Nr,3,'single');                   % Vamos guardar o tempo de Tx decorrido por frame, se houve underrun e se houve overrun
    
    Ry = zeros(toneSamples*Nframes,1,'double');  % Vamos guardar o sinal num vetor coluna (todas as frames)
    k = 1;                                       % Contador de frames
    
    %% 7 - Inicializa o Receptor
    % Espera que o receptor receba uma frame
    dataLen = 0;
    
    while dataLen == 0
        [y,dataLen] = rx_SDRu();
    end
    
    %% 8 - Opera��o de Transmiss�o
    disp('Starting capture');
    tic                                             % Inicia contador
    for iFrame = 1: Nframes
        sinewave = step(hSineSource);               % executa o objecto sinal sinusoide
        underrun = step(tx_SDRu, sinewave);         % executa o objecto front-end TX
        [x,dataLen,overrun] = rx_SDRu();            % executa o objecto front-end RX
        Rt(k,1) = toc;                              % guarda o instante em que foi recebida a frame k
        Rt(k,2) = overrun;                          % indico se o pacote k n�o foi recebido
        Rt(k,3) = underrun;                         % indico se o pacote k n�o foi transmitido
        Ry((((k-1)*toneSamples)+1):(k*toneSamples),1) = x;              % guarda a frame no vetor sinal
        k = k+1;
    end
    
    %% 9 - Release dos objectos
    % Libertar os objetos criados neste script - sen�o n�o podem ser modificados
    % Limpa a memoria da utiliza��o dos objetos criados para aquisicao.
    release (hSineSource);
    release (tx_SDRu);
    release (rx_SDRu);
    clear tx_SDRu
    clear rx_SDRu
    clear hSineSource
    
    %% 10 - Calculos para averiguar a exist�ncia de underrun e overrun
    Under = find(Rt(:,3) == 1);
    if isempty(Under)
        disp('N�o houve perda de frames na transmiss�o');
    else
        disp(['Numero de frames perdidas na transmiss�o = ' num2str(length(Under))]);
    end
    
    Over = find(Rt(:,2) == 1);
    if isempty(Over)
        disp('N�o houve perda de frames na recep��o');
    else
        disp(['Numero de frames perdidas na recep��o = ' num2str(length(Over))]);
    end
    
end

if md_memory
    Ry = load('Ry_b210_POtimo');        % Sinal 2.1
    %Ry = load('Ry_b210_new');           % Sinal 2.2
    Ry = Ry.Ry;
    
    % Variaveis de aquisi��o
    toneSampRate = 100e3;
    T = 100;
    toneFreq = 10e3;
    
% Nota: se usarmos o sinal 2.2 mudar o start_sample em 11.3
end

%% 11- Pos - processamento
%% 11.1 - Passar para banda base
% Remover a componente 10 kHz
time_norm = (0:toneSampRate*T-1)/toneSampRate;          % Vetor tempo
aux = exp(-1j*2*pi*toneFreq*time_norm');                % Sinal complexo auxiliar
sinal_bb1 = aux.*Ry;                                    % Passagem para banda base

%% 11.2 - Decima��o
M = 1000;                                               % Fator de Decimacao
fa2 = toneSampRate/M;                                   % Nova frequ�ncia de amostragem
sinal_bb1_D1 = decimate(sinal_bb1,M);                   % Sinal decimado

%% 11.3 - Sinal �til
% Olhando para o sinal em fase, as primeiras amostras s�o transi��es entre
% pi e -pi. O sinal �til n�o contempla essas amostras. Cortar!
figure; plot(angle(sinal_bb1_D1)); title('Sinal desmodulado em fase total')

start_sample = 143;                     % Amostra onde come�a o sinal util (� 143 tipicamente para T = 100);
%start_sample = 411;                   % Caso seja o sinal 2.2 da memoria
sinal_bb1_D1 = sinal_bb1_D1(start_sample:end);   % Sinal util

%% 11.3 - Visualiza��o do diagrama polar do sinal util em banda base
% Estamos � espera de ver um arco algures no plano complexo
figure; polarplot(angle(sinal_bb1_D1), abs(sinal_bb1_D1)); title('Diagrama polar sinal util em banda base')

%% 11.4 - Desmodula��o em fase
resp = angle(sinal_bb1_D1);
time = (0:fa2*T-1)/fa2;                                 % Vetor tempo
time_min = time(start_sample:end)/60;                   % Vetor tempo em minutos

figure; plot(time_min, resp); title('Sinal Desmodulado em fase')
axis([time_min(1) time_min(end) min(resp)-0.1 max(resp)+0.1])
xlabel('Tempo (min)');
ylabel('Fase (radianos)');