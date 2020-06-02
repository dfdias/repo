

runtime = zeros(1,10);


 Ry = load('Ry_b210_POtimo.mat');
Ry=Ry.Ry;
    i = i +1;

    toneSampRate = 100e3;
    T = 100;
    toneFreq = 10e3;
    
% Nota: se usarmos o sinal 2.2 mudar o start_sample em 11.3
idx = 0

%% 11- Pos - processamento
%% 11.1 - Passar para banda ba    
tic()
  idx = idx +1;

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
% figure; polarplot(angle(sinal_bb1_D1), abs(sinal_bb1_D1)); title('Diagrama polar sinal util em banda base')

%% 11.4 - Desmodula��o em fase
resp = angle(sinal_bb1_D1);
time = (0:fa2*T-1)/fa2;                                 % Vetor tempo
time_min = time(start_sample:end)/60;                   % Vetor tempo em minutos

 figure; plot(time_min, resp); title('Sinal Desmodulado em fase')
 axis([time_min(1) time_min(end) min(resp)-0.1 max(resp)+0.1])
 xlabel('Tempo (min)');
 ylabel('Fase (radianos)');

toc();


display(mean(runtime))