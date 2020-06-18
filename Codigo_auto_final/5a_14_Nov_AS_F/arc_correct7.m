function [xD_DC_rot, freq] = arc_correct6(xD_DC, debug)
%% Implementa��o da corre��o do arco autom�tica com o m�todo 1 com EXTRA
%% Descri��o M�todo 3 (vers�o 6):
% Com m�todo 3 o objetivo � rodar de maneira que a parte interior concava
% fique virada para a origem e � volta dos 0�. Ou seja, o arco deve de
% ocupar o 1� e 4� Quadrante. Assim garantimos que o movimento � recuperado
% como deve de ser.

% FASE 1:
% 1- Condi��o QQ: Enquanto houverem samples ap�s +- 135� 2� e 3� quadrante,
% significa que o arco ainda n�o rodou completamente para o
% 1� e 4� quadrante.
%       1.1- Vamos rodando o arco pi/5 em pi/5 at� que n�o se verifique a
%       condi��o QQ
%       1.2- Se j� tivermos dado um total de 10 voltas, significa que o
%       arco j� deu uma volta completa. Tem amostras demasiado dispersas e
%       portanto tem que ser acrescentado um offset
% FASE 2:
% 2- Como na fase anterior o sinal voltou ao mesmo sitio, � necess�rio
% roda-lo de forma a que fique � volta dos 0� de preferencia com a
% concavidade interior voltada para a origem. Assumindo que o sinal no eixo
% y tem um comprimento superior ao eixo x, quando est� na posi��o desejada,
% calculam-se os valores max e min de cada eixo.
%       2.1 - Com esses valores min e max s�o definidas 3 condi��es. O arco
%       � rodado de pi/5 em pi/5 enquanto essas condi��es n�o se
%       verificarem.
%           2.1.1 - Cond1 - a X width < 0.01
%           2.1.2 - Cond2 - a X width < Y width
%           2.1.3 - � calculado um fit do arco a uma par�bola. Temos a
%       concavidade voltada para dentro quando o elemento quadr�tico da
%       par�bola encontrada for negativo.
%       2.2 - Caso n�o seja possivel com as condi��es definidas em 2.1
%       rodar o arco para a posi��o certa, aumentamos a largura admissivel
%       de X width para 0.03. Sen�o, passa para a adi��o de offset.
% FASE 3:
% 3- Acrescentar offset. O offset come�a por ser inicializado a um valor
% baixo que � incrementado o necess�rio. A condi��o limite � at� termos
% Xmin negativo. O offset s� � acrescentado na parte real.
%       3.1 - No final do offset a condi��o QQ e verifiada outra vez, para
%       poder sair desse ciclo.
% FASE 4:
% 4- Calculamos a frequencia do sinal respirat�rio extra�do.
%       4.1 - Como o sinal n�o est� exatamente centrado em zero, �
%       necess�rio remover a componente m�dia, para que o pico detetado n�o
%       seja DC, mas sim o pico de interesse. Portanto, o sinal usado para
%       a avalia��o espetral � resp = angle(sfinal) - mean(angle(sfinal));
%       4.2 - Para calcular a freq � usado o m�todo WELCH com uma
%       interpola��o de fator 10.
%       4.3 - Quando o sinal under test altera abruptamente a sua m�dia, o
%       primeiro pico detetado � mais uma vez a m�dia. Nesse caso
%       considera-se o segundo pico detetado.
%       4.4 - O m�todo welch n�o tem precis�o suficiente para frequencas
%       muito baixas (abaixo dos 0.15 Hz). Nesse caso � usada a FFT normal.

%% Vari�veis
% Input - xD_DC - sinal complexo sem componente DC
%       - debug - Se '1' ativar o modo debug para ver cada plot em cada
%       itera��o. Se '0', desativar o modo debug. Se diferente de '1' ou
%       '0', gerar erro de input.
%       - debug_rot - Se '0' usa o numero de voltas default que s�o 7
%       Se > 0, a seguir �s 10 voltas d� N voltas, sendo N = debug_rot;
% Output - xD_DC_rot - sinal compensado com rota��o e eventualmente offset
%        - freq_pwelch - devolve a frequ�ncia respirat�ria

%% Codigo da fun��o
% Verifica o n� de inputs
if nargin < 2
    error('Not enough inputs')
elseif nargin > 2
    error('Too many inputs')
elseif nargin == 2

    % Verifica��o do modo debug
    if debug == 1
        db_debug = 1;
    elseif debug == 0
        db_debug = 0;
    else
        error('Please insert 0 or 1')
    end
%% FASE 1    
    xD_DC_rot = xD_DC;
    Q = angle(xD_DC_rot);                           % Calcula condi��o QQ inicial
    rad = 6*pi/8;                                  
    R = find(Q > rad | Q < - rad);                  % Define a condi��o QQ
    qq1 = 0;                                        % Inicializa o contador de voltas
    
    while ~isempty(R)                               % Quando 'R' for um array vazio, pára de rodar
        % Roda
        aux = exp(-1j*(pi/5));                      % Sinal auxilixar para rodar
        xD_DC_rot = aux*xD_DC_rot; % Inicilizar a variavel xD_DC_rot com o sinal complexo no input
        xD_DC_rot_i = imag(xD_DC_rot);
        xD_DC_rot_r = real(xD_DC_rot);
  
        Q = angle(xD_DC_rot);                       
       
        % Roda pi/5                       
        R = find(Q > rad | Q < - rad);              % Atualiza a condição QQ
        qq1 = qq1+1;                                % Incrementa volta
        
        % Debug 1 - verificar se o arco d� a volta completa
        if db_debug
            polarplot(angle(xD_DC_rot)),abs(xD_DC_rot))
            pause;                                  % Em cada ciclo
        end
        
        if qq1 > 10                                 % Se o contador for igual a 10 voltas passamos a FASE 2
            % Aviso 1
            if db_debug
                fprintf('Terminadas as 10 voltas \n');
            end
%% FASE 2            
            % Cacula X e Y lim
            ylim_min = min(xD_DC_rot_i);        % Calcula ymin
            ylim_max = max(xD_DC_rot_i);        % Calcula ymax
            Ywidth = ylim_max - ylim_min;           % Calcula Ywidth
            
            xlim_min = min(xD_DC_rot_r);        % Calcula xmin
            xlim_max = max(xD_DC_rot_r);        % Calcula xmax
            Xwidth = xlim_max - xlim_min;           % Calcula Xwidth

            % An�lise da concavidade
            %f = fit(real(xD_DC_rot_r', imag(xD_DC_rot)', 'poly2');   % Faz fit ao arco
            f = fit(xD_DC_rot_r', xD_DC_rot_i', 'poly2');
            coeffvals= coeffvalues(f);              % Vai buscar os coeficientes do polinomio de grau 2
            coeffvals = coeffvals(1);
            % Debug 2 - verificar os XY lim e coeficiente 1
            if db_debug
                fprintf('xwidth = %0.5f \n', Xwidth);
                fprintf('Ywidth = %0.5f \n', Ywidth);
                fprintf('Coef = %0.5f \n', coeffvals);
            end
            
            flag = 0;                               % Flag repiti��o FASE 2
            qq3 = 0;                                % Inicializa contador de voltas
            cond1 = Xwidth > 0.01;                  % Define cond1
            bool = 1;
            cond2 = bool;
                
            cond3 = Ywidth < Xwidth;                % Define cond3
            fprintf('stage2\n');  % as 8, 9 ou 10 de julhoond2             % Enquanto se verificarem as condi��es
            while cond1 | cond3 | cond2             % Enquanto se verificarem as condi��es

               % aux = exp(-1j*(pi/5));              % Sinal auxilixar para rodar
                xD_DC_rot = aux*xD_DC_rot;          % Roda pi/5
                xD_DC_rot_i = imag(xD_DC_rot);
                xD_DC_rot_r = real(xD_DC_rot);
                %xD_DC_rot_ang = angle(xD_DC_rot); 
                %xD_DC_rot_abs = abs(xD_DC_rot);        
                % Atualiza XY lim e coef
                 % Cacula X e Y lim
                ylim_min = min(xD_DC_rot_i);        % Calcula ymin
                ylim_max = max(xD_DC_rot_i);        % Calcula ymax
                Ywidth = ylim_max - ylim_min;           % Calcula Ywidth
            
                xlim_min = min(xD_DC_rot_r);        % Calcula xmin
                xlim_max = max(xD_DC_rot_r);        % Calcula xmax
                Xwidth = xlim_max - xlim_min;           % Calcula Xwidth

                f = fit(xD_DC_rot_r', xD_DC_rot_i', 'poly2');
                coeffvals1= coeffvalues(f);
                coeffvals = [coeffvals coeffvals1(1)];
                
                % Debug 3 - verificar os XY lim e coeficiente 1
                if db_debug
                    fprintf('xwidth = %0.5f \n', Xwidth);
                    fprintf('Ywidth = %0.5f \n', Ywidth);
                    fprintf('Coef = %0.5f \n', coeffvals(end));
                    polarplot(angle(xD_DC_rot)),abs(xD_DC_rot)); title('Diagrama polar sinal original')
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
                
                % Atualiza condi��es while
                cond1 = Xwidth > 0.01;
                cond3 = Ywidth < Xwidth;
                cond2 = bool;
                
                if qq3 == 10 & flag == 0            % Caso tenhamos dado 10 voltas e ainda nao tenhamos repetido a FASE 2
                    fprintf('Ainda n�o foi possivel otimizar o arco\n');
                    cond1 = Xwidth > 0.03;          % Incrementar Xwidth permitido
                    flag = 1;                       % Ativa flag de repeticao FASE 2
                    qq3 = 0;                        % Inicializa contador de rota��es
                    bool = 0;
                    continue;                       % Repete FASE 2
                elseif qq3 == 10 & flag == 1        % Caso j� tenhamos repetido a FASE 2 uma vez
                    fprintf('NAO foi possivel otimizar o arco\n');
                    break;                          % Avan�amos para o offset
                end
                
            end
       
      %% FASE 3
            Q = angle(xD_DC_rot);                  
            R = find( Q > rad | Q < - rad);         % Atualiza a condi��o QQ
            offset = 1e-4;                          % Inicializa o offset
            
            % Aviso 2
            if db_debug
                fprintf('Iniciar offset\n');
            end
            
            xlim_min = min(real(xD_DC_rot));        % Condi��o while xmin

            while (xlim_min <= 0)                   % Enquanto houverem samples com x negativo
                xD_DC_rot = xD_DC_rot + offset;     % Acrescenta offset
                offset = offset + 1e-4;             % Incrementa offset
                Q = angle(xD_DC_rot);               % Atualiza a condi��o QQ
                R = find( Q > rad | Q < - rad);     % Atualiza a condi��o QQ
                
                xlim_min = min(real(xD_DC_rot));    % Atualiza a condicao while
                
                % Debug 4 - verificar em que ponto o arco p�ra de ter offset
                if db_debug
                    polarplot(angle(xD_DC_rot),abs(xD_DC_rot))
                    pause;
                end
            end
        end
    end
    
    %% Calculo da freq respiratoria
    % Defini��o variaveis
    fa2 = 100;                                      % Defini��o da freq. amostragem
    resp = angle(xD_DC_rot) - mean(angle(xD_DC_rot));           % Sinal respirat�rio centrado em zero
    L = length(resp);                               % Tamanho do sinal
    NFFT = 2^nextpow2(L);                           % N� pontos FFT baseado no seu tamanho
    % WELCH
    [F1, F2] = pwelch(resp, [], [], NFFT, fa2);     % 1� calculo WELCH para retirar o vetor frequencias
    F2i = linspace(F2(1),F2(end),length(F2));       % Cria��o vetor frequencias
    p = pwelch(resp, [], [], NFFT, fa2);            % 2� calculo WELCH
    % Interpola��o
    t_interp = linspace(min(F2i), max(F2i), 10*length(F2i));    % Vetor freq interpolado por 10
    x_interp = interp1(F2i, p, t_interp, 'spline'); % Interpola��o fator 10 com spline
    % Procurar picos
    [PKS,LOCS] = findpeaks(x_interp,'SortStr','descend');       % Coloca os picos encontrados por ordem decrescente de magnitude
    
    if t_interp(LOCS(1)) > 0.05 & t_interp(LOCS(1)) < 0.55      % Se o pico for maior que 0.05 n�o � DC e se for menor que 0.55 n�o houve erros
        freq = t_interp(LOCS(1));                               % CNesse caso considerar o primeiro pico
        fprintf('[PWELCH]Frequencia detetada %0.2f Hz\n', freq);
    elseif t_interp(LOCS(2)) > 0.05 & t_interp(LOCS(2)) < 0.55  % Se n�o for o primeiro pico, considera-se o segundo
        freq = t_interp(LOCS(2));
        fprintf('[PWELCH]Frequencia detetada %0.2f Hz\n', freq);
    else                                                        % Se n�o for o segundo pico usamos a FFT
        % FFT
        f = fa2/2*linspace(0,1,NFFT/2+1);           % Eixo de frequencias para o plot
        test = fft(resp ,NFFT/2+1)/L;               % Calculo da FFT
        % Interpola��o
        t_interp = linspace(min(f), max(f), 10*length(f));
        x_interp = interp1(f, test, t_interp, 'spline');
        % Procurar picos
        [PKS,LOCS] = findpeaks(abs(x_interp(1:NFFT/2+1)),'SortStr','descend');
        freq = (LOCS(1)/length(x_interp))*fa2;      % Define o pico encontrado
        
        if freq > 0.05                              % Se o pico for maior que 0.05 nao e DC
            freq = (LOCS(1)/length(x_interp))*fa2;
        else                                        % Se n�o, considera-se o segundo pico
            freq = (LOCS(2)/length(x_interp))*fa2;
        end
        
        fprintf('[FFT] Frequencia detetada %0.2f Hz\n', freq);
    end
    
end
end
