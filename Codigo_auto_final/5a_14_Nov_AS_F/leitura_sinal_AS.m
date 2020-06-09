%% Carolina Gouveia - 27 Março 2020
% Teste do método de automatização do código

clear all; clc; close all
fa = 100e3;   %frequência de amostragem da aquisição em LabView

%% Descrição dos sinais
% Sinais adquiridos durante a experiencia PsyLAB, segunda ronda, AS_F

%% Flags debug
db_debug = 0;       % Para executar o codigo de automatização em modo debug (ver os plots passo a passo)

%% Leitura do sinal
n = 1;
for k=19:25
    fname = sprintf('seg_%d.mat', k);
    S(n) = load(fname,'sinal');
    n = n+1;
end
s18 = S(1).sinal;
num_sinais = 7;

%% Ver o sinal complexo inicial?
% figure; polarplot(angle(s18), abs(s18));
%%
%% Circle fit e remoção da componente DC
I_DC = ones(num_sinais,length(real(s18)));
Q_DC = ones(num_sinais,length(imag(s18)));
xD_DC = ones(num_sinais,length(s18));

for k=1:num_sinais
    XRt = S(k).sinal;
    [xc(k),yc(k),Re,a] = circfit(real(XRt),imag(XRt));
    I_DC(k,:) = real(XRt)-xc(k);
    Q_DC(k,:) = imag(XRt)-yc(k);
    xD_DC(k,:) = I_DC(k,:)+(1i*Q_DC(k,:));
end

%% Verificar método
xD_DC_rot3 = ones(num_sinais,length(s18));

for k = 1:num_sinais
    [xD_DC_rot3(k,:), freq_pwelch] = arc_correct7(xD_DC(k,:), db_debug);
    fa2 = 100;
    [b10,a10] = fir1(10, 10/(fa2/2));
    phase_f10_R3 = filter(b10,a10,xD_DC_rot3(k,:));
    t_R = (0:length(xD_DC_rot3(k,:))-1)*(1/fa2);
    
    phase3 = angle(phase_f10_R3);
    
    figure;
    hT3 = plot(t_R,phase3,'b');
    axis([1 t_R(end) -2.5 2.5])
    set(hT3, 'LineWidth',1.2)
    set(gca, 'FontSize', 15)
    xlabel('Time (s)'); ylabel('Phase (rad)');
end

%% Ver o sinal complexo final?
%figure; polarplot(angle(xD_DC_rot3(6,:)),abs(xD_DC_rot3(6,:)))
%%
   