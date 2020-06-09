function [xD_DC_rot, freq] = arc_correct6(xD_DC, debug)
%% Implementação da correção do arco automática com o método 1 com EXTRA
%% Descrição Método de automatização:
% Com método de automatização o objetivo é rodar de maneira que a parte interior concava
% fique virada para a origem e á volta dos 0º. Ou seja, o arco deve de
% ocupar o 1º e 4º Quadrante. Assim garantimos que o movimento é recuperado
% como deve de ser.

% FASE 1:
% 1- Condição QQ: Enquanto houverem samples após +- 135º 2º e 3º quadrante,
% significa que o arco ainda não rodou completamente para o
% 1º e 4º quadrante.
%       1.1- Vamos rodando o arco pi/5 em pi/5 até que não se verifique a
%       condição QQ
%       1.2- Se já tivermos dado um total de 10 voltas, significa que o
%       arco já deu uma volta completa. Tem amostras demasiado dispersas e
%       portanto tem que ser acrescentado um offset
% FASE 2:
% 2- Como na fase anterior o sinal voltou ao mesmo sitio, é necessário
% roda-lo de forma a que fique à volta dos 0º de preferencia com a
% concavidade interior voltada para a origem. Assumindo que o sinal no eixo
% y tem um comprimento superior ao eixo x, quando está na posição desejada,
% calculam-se os valores max e min de cada eixo.
%       2.1 - Com esses valores min e max são definidas 3 condições. O arco
%       é rodado de pi/5 em pi/5 enquanto essas condições não se
%       verificarem.
%           2.1.1 - Cond1 - a X width < 0.01
%           2.1.2 - Cond2 - a X width < Y width
%           2.1.3 - É calculado um fit do arco a uma parábola. Temos a
%       concavidade voltada para dentro quando o elemento quadrático da
%       parábola encontrada for negativo.
%       2.2 - Caso não seja possivel com as condições definidas em 2.1
%       rodar o arco para a posição certa, aumentamos a largura admissivel
%       de X width para 0.03. Senão, passa para a adição de offset.
% FASE 3:
% 3- Acrescentar offset. O offset começa por ser inicializado a um valor
% baixo que é incrementado o necessário. A condição limite é enquanto
% tivermos Xmin negativo. O offset só é acrescentado na parte real.
%       3.1 - No final do offset a condição QQ e verificada outra vez, para
%       poder sair desse ciclo.
% FASE 4:
% 4- Calculamos a frequencia do sinal respiratório extraído.
%       4.1 - Como o sinal não está exatamente centrado em zero, é
%       necessário remover a componente média, para que o pico detetado não
%       seja DC, mas sim o pico de interesse. Portanto, o sinal usado para
%       a avaliação espetral é resp = angle(sfinal) - mean(angle(sfinal));
%       4.2 - Para calcular a freq é usado o método WELCH com uma
%       interpolação de fator 10.
%       4.3 - Quando o sinal under test altera abruptamente a sua média, o
%       primeiro pico detetado é mais uma vez a média. Nesse caso
%       considera-se o segundo pico detetado.
%       4.4 - O método welch não tem precisão suficiente para frequencas
%       muito baixas (abaixo dos 0.15 Hz). Nesse caso é usada a FFT normal.

%% Variáveis
% Input - xD_DC - sinal complexo sem componente DC
%       - debug - Se '1' ativar o modo debug para ver cada plot em cada
%       iteração. Se '0', desativar o modo debug. Se diferente de '1' ou
%       '0', gerar erro de input.
%       - debug_rot - Se '0' usa o numero de voltas default que são 7
%       Se > 0, a seguir às 10 voltas dá N voltas, sendo N = debug_rot;
% Output - xD_DC_rot - sinal compensado com rotação e eventualmente offset
%        - freq_pwelch - devolve a frequência respiratória

%% Codigo da função
% Verifica o nº de inputs
if nargin < 2
    error('Not enough inputs')
elseif nargin > 2
    error('Too many inputs')
elseif nargin == 2

    % Verificação do modo debug
    if debug == 1
        db_debug = 1;
    elseif debug == 0
        db_debug = 0;
    else
        error('Please insert 0 or 1')
    end
%% FASE 1    
    xD_DC_rot = xD_DC;                              % Inicilizar a variavel xD_DC_rot com o sinal complexo no input
    Q = angle(xD_DC_rot);                           % Calcula condição QQ inicial
    rad = 6*pi/8;                                  
    R = find(Q > rad | Q < - rad);                  % Define a condição QQ
    qq1 = 0;                                        % Inicializa o contador de voltas
    
    while ~isempty(R)                               % Quando 'R' for um array vazio, pára de rodar
        % Roda
        aux = exp(-1j*(pi/5));                      % Sinal auxilixar para rodar
        xD_DC_rot = aux*xD_DC_rot;                  % Roda pi/5
        Q = angle(xD_DC_rot);                       
        R = find(Q > rad | Q < - rad);              % Atualiza a condição QQ
        qq1 = qq1+1;                                % Incrementa volta
        
        % Debug 1 - verificar se o arco dá a volta completa
        if db_debug
            polarplot(angle(xD_DC_rot),abs(xD_DC_rot))
            pause;                                  % Em cada ciclo
        end
        
        if qq1 > 10                                 % Se o contador for igual a 10 voltas passamos a FASE 2
            % Aviso 1
            if db_debug
                fprintf('Terminadas as 10 voltas \n');
            end
%% FASE 2            
            % Cacula X e Y lim
            ylim_min = min(imag(xD_DC_rot));        % Calcula ymin
            ylim_max = max(imag(xD_DC_rot));        % Calcula ymax
            Ywidth = ylim_max - ylim_min;           % Calcula Ywidth
            
            xlim_min = min(real(xD_DC_rot));        % Calcula xmin
            xlim_max = max(real(xD_DC_rot));        % Calcula xmax
            Xwidth = xlim_max - xlim_min;           % Calcula Xwidth

            % Análise da concavidade
            f = fit(real(xD_DC_rot)', imag(xD_DC_rot)', 'poly2');   % Faz fit ao arco
            coeffvals= coeffvalues(f);              % Vai buscar os coeficientes do polinomio de grau 2
            coeffvals = coeffvals(1);
            % Debug 2 - verificar os XY lim e coeficiente 1
            if db_debug
                fprintf('xwidth = %0.5f \n', Xwidth);
                fprintf('Ywidth = %0.5f \n', Ywidth);
                fprintf('Coef = %0.5f \n', coeffvals);
            end
            
            flag = 0;                               % Flag repitição FASE 2
            qq3 = 0;                                % Inicializa contador de voltas
            cond1 = Xwidth > 0.01;                  % Define cond1
            bool = 1;
            cond2 = bool;
                
            cond3 = Ywidth < Xwidth;                % Define cond3
            fprintf('stage2\n');          
            
            while cond1 | cond3 | cond2             % Enquanto se verificarem as condições

                aux = exp(-1j*(pi/5));              % Sinal auxilixar para rodar
                xD_DC_rot = aux*xD_DC_rot;          % Roda pi/5
                
                % Atualiza XY lim e coef
                ylim_min = min(imag(xD_DC_rot));
                ylim_max = max(imag(xD_DC_rot));
                Ywidth = ylim_max - ylim_min;
                
                xlim_min = min(real(xD_DC_rot));
                xlim_max = max(real(xD_DC_rot));
                Xwidth = xlim_max - xlim_min;

                f = fit(real(xD_DC_rot)', imag(xD_DC_rot)', 'poly2');
                coeffvals1= coeffvalues(f);
                coeffvals = [coeffvals coeffvals1(1)];
                
                % Debug 3 - verificar os XY lim e coeficiente 1
                if db_debug
                    fprintf('xwidth = %0.5f \n', Xwidth);
                    fprintf('Ywidth = %0.5f \n', Ywidth);
                    fprintf('Coef = %0.5f \n', coeffvals(end));
                    polarplot(angle(xD_DC_rot),abs(xD_DC_rot)); title('Diagrama polar sinal original')
                    pause;
                end
                
                qq3 = qq3+1;                        % Incrementa uma volta
                
                if flag == 0
                    if coeffvals(end-1) < 0 & coeffvals(end) > 0
                        %                 aux = exp(1j*(pi/5));              % Sinal auxilixar para rodar
                        %                 xD_DC_rot = aux*xD_DC_rot;          % Roda pi/5
                        bool = 0;
                    else
                        bool=1;
                    end
                end
                
                % Atualiza condições while
                cond1 = Xwidth > 0.01;
                cond3 = Ywidth < Xwidth;
                cond2 = bool;
                
                if qq3 == 10 & flag == 0            % Caso tenhamos dado 10 voltas e ainda nao tenhamos repetido a FASE 2
                    fprintf('Ainda não foi possivel otimizar o arco\n');
                    cond1 = Xwidth > 0.03;          % Incrementar Xwidth permitido
                    flag = 1;                       % Ativa flag de repeticao FASE 2
                    qq3 = 0;                        % Inicializa contador de rotações
                    bool = 0;
                    continue;                       % Repete FASE 2
                elseif qq3 == 10 & flag == 1        % Caso já tenhamos repetido a FASE 2 uma vez
                    fprintf('NAO foi possivel otimizar o arco\n');
                    break;                          % Avançamos para o offset
                end
                
            end
       
      %% FASE 3
            Q = angle(xD_DC_rot);                  
            R = find( Q > rad | Q < - rad);         % Atualiza a condição QQ
            offset = 1e-4;                          % Inicializa o offset
            
            % Aviso 2
            if db_debug
                fprintf('Iniciar offset\n');
            end
            
            xlim_min = min(real(xD_DC_rot));        % Condição while xmin

            while (xlim_min <= 0)                   % Enquanto houverem samples com x negativo
                xD_DC_rot = xD_DC_rot + offset;     % Acrescenta offset
                offset = offset + 1e-4;             % Incrementa offset
                Q = angle(xD_DC_rot);               % Atualiza a condição QQ
                R = find( Q > rad | Q < - rad);     % Atualiza a condição QQ
                
                xlim_min = min(real(xD_DC_rot));    % Atualiza a condicao while
                
                % Debug 4 - verificar em que ponto o arco pára de ter offset
                if db_debug
                    polarplot(angle(xD_DC_rot),abs(xD_DC_rot))
                    pause;
                end
            end
        end
    end
    
    %% Calculo da freq respiratoria
    % Definição variaveis
    fa2 = 100;                                      % Definição da freq. amostragem
    resp = angle(xD_DC_rot) - mean(angle(xD_DC_rot));           % Sinal respiratório centrado em zero
    L = length(resp);                               % Tamanho do sinal
    NFFT = 2^nextpow2(L);                           % Nº pontos FFT baseado no seu tamanho
    % WELCH
    [F1, F2] = pwelch(resp, [], [], NFFT, fa2);     % 1º calculo WELCH para retirar o vetor frequencias
    F2i = linspace(F2(1),F2(end),length(F2));       % Criação vetor frequencias
    p = pwelch(resp, [], [], NFFT, fa2);            % 2º calculo WELCH
    % Interpolação
    t_interp = linspace(min(F2i), max(F2i), 10*length(F2i));    % Vetor freq interpolado por 10
    x_interp = interp1(F2i, p, t_interp, 'spline'); % Interpolação fator 10 com spline
    % Procurar picos
    [PKS,LOCS] = findpeaks(x_interp,'SortStr','descend');       % Coloca os picos encontrados por ordem decrescente de magnitude
    
    if t_interp(LOCS(1)) > 0.05 & t_interp(LOCS(1)) < 0.55      % Se o pico for maior que 0.05 não é DC e se for menor que 0.55 não houve erros
        freq = t_interp(LOCS(1));                               % CNesse caso considerar o primeiro pico
        fprintf('[PWELCH]Frequencia detetada %0.2f Hz\n', freq);
    elseif t_interp(LOCS(2)) > 0.05 & t_interp(LOCS(2)) < 0.55  % Se não for o primeiro pico, considera-se o segundo
        freq = t_interp(LOCS(2));
        fprintf('[PWELCH]Frequencia detetada %0.2f Hz\n', freq);
    else                                                        % Se não for o segundo pico usamos a FFT
        % FFT
        f = fa2/2*linspace(0,1,NFFT/2+1);           % Eixo de frequencias para o plot
        test = fft(resp ,NFFT/2+1)/L;               % Calculo da FFT
        % Interpolação
        t_interp = linspace(min(f), max(f), 10*length(f));
        x_interp = interp1(f, test, t_interp, 'spline');
        % Procurar picos
        [PKS,LOCS] = findpeaks(abs(x_interp(1:NFFT/2+1)),'SortStr','descend');
        freq = (LOCS(1)/length(x_interp))*fa2;      % Define o pico encontrado
        
        if freq > 0.05                              % Se o pico for maior que 0.05 nao e DC
            freq = (LOCS(1)/length(x_interp))*fa2;
        else                                        % Se não, considera-se o segundo pico
            freq = (LOCS(2)/length(x_interp))*fa2;
        end
        
        fprintf('[FFT] Frequencia detetada %0.2f Hz\n', freq);
    end
    
end
end

