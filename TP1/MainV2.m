clear all; close all; clc

%% Captura da Imagem

NumberFrameDisplayPerSecond = 30;% Define o Frame Rate
% Liberta a Camara ao Correr o Codigo
objects = imaqfind; % Encontra Entrada de Video na Memoria
delete(objects)

% Set-up da Entrada de Video
try
    vid = videoinput('winvideo', 1, 'RGB24_1280x720');% Windows, Ze tem de ser RGB24_1280x720, Normal: MJPG_1280x720
catch
    try
        vid = videoinput('macvideo', 1); % Macs.
    catch
        errordlg('No webcam available');% Em caso de erro
    end
end

% Define os Parametros para o Video
set(vid,'FramesPerTrigger',1);% Aquisicao de um Frame
set(vid,'TriggerRepeat',Inf);% Aquisicao Continua
set(vid,'ReturnedColorSpace','RGB');% Aquisicao de Imagem em RGBa
triggerconfig(vid, 'Manual');

while true
    % Timer que Chama a Funcao Processamento
    TimerData=timer('TimerFcn', {@Processamento,vid},'Period',1/NumberFrameDisplayPerSecond,'ExecutionMode','fixedRate','BusyMode','drop');

    start(vid); %Inicio do Video
    start(TimerData); %Inicio do Timer
end

%     Apaga os Objectos Criados
stop(TimerData);
delete(TimerData);
stop(vid);
delete(vid);
% Apaga as Variaveis do Tipo Persistent
clear functions;
imaqreset;

%% Função Processamento
function Processamento(obj, event,vidd)% Funcao que e chamada de n em n segundo
% Variaveis do Tipo Persistent para Evitar Estar Sempre a Alocar Memoria
persistent im;

trigger(vidd);% Da um Trigger
im = getdata(vidd,1,'uint8');%l? os dados da imagem

%imshow da camera
% hFigure = figure(1);% Abre uma figura em tempo real
% imshow(im); % apresenta a imagem inicial
%isto cracha se as vezes houver p exemplo um um imshow qualqer tdo fdd


% Declaração de variáveis
n = 0; %Variavel chave, ou condiçao de paragem
maskRed = 0;
maskYellow = 0;
maskBlue = 0;
im = flip(im ,2); % Espelhar a Imagem, pois a Camara Espelha a Real

%% Aplicação das máscaras
while n < 5 %caso chega a 5, parou, MASSS, perguntar ao chatGPT!!!
    switch n
        case 0 % Amarelo
            m_bin = createMaskYellowHSV(im); % Aplicar um Threshold cor Amarela
            matrix = strel('square',15);% Matriz para Percorer a Imagem 15x15
            Fecho_Im = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(Fecho_Im,'holes');% Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);%concatenar os objectos que encontra, mete no array

            % Eliminar Objetos Indesejados / Ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else
                for i=1:rw        %parte eliminar os pequenos ponto a volta do shape
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0;  % Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end

                % Se for o sinal com Cor Correspondente
                maskYellow = 1; %% Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end


        case 1 %Azul
            m_bin = createMaskBlueHSV(im); % Aplicar um Threshold cor Azul
            matrix = strel('square',25);% Matriz para Percorer a Imagem 15x15
            Fecho_Im = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(Fecho_Im,'holes'); % Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);
            % Eliminar objetos indesejados / ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else  % Se for o Sinal com Cor Correspondente
                for i=1:rw
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0; % Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end
                maskBlue = 1; %% Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end
        case 2 % Vermelho
            m_bin = createMaskRedHSV(im);  % Aplicar um Threshold cor Vermelha
            matrix = strel('square',30);% Matriz para Percorer a Imagem 15x15
            Fecho_Im = imclose(m_bin,matrix); % Fecho Morfologico da Imagem
            BW2 = imfill(Fecho_Im,'holes'); % Preenchimento do Interior da do Sinal
            % Eliminar ruído
            stats =  regionprops(BW2,'PixelIdxList','Area');% Retirar as Areas de todos os Objetos Detetados na Imagem
            Area = cat(1,stats.Area);
            % Eliminar Objetos Indesejados / Ruído
            [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
            [rw col]= size(stats);
            if maxValue < 5000 % Se a Area do Objeto Maior for Mais Pequena do que o Tamanho de um Sinal Normal
                n = n + 1; % Avanca para o Proximo Filtro
            else % Se for o Sinal com Cor Correspondente
                for i=1:rw
                    if (i~=index)
                        BW2(stats(i).PixelIdxList) = 0;% Remove Todas as Pequenas Regions a Excepcao da Area Maior
                    end
                end
                maskRed = 1; % Guarda o Tipo de Mascara
                n = 4; %Avança para o Processamento
            end
        case 3
            disp('Nenhum Sinal Detetado');% Caso nao Seja Detetado Nenhum Sinal Fecha o Codigo
            n = 5; % reset
        case 4
            %% Forma do Objeto Principal, ver se triangule, circulo, quadrado
            [isCircle, isTriangle, isSquare, BW2] = detect_figures(im);


            %%  Multiplicar as imagens
            multi = uint8(BW2); % Converter para 8bits
            submask = im.*multi; % Multiplicar a Imagem Binaria com a Original

            %Explicação Sampaio, gravar.
            %caso tiver um sinal de perigo de passadeira ou rochedo a cair.
            %% Aplicação da Segunda Mascara e Identificação do Sinal

            %% Começar verificar sinais
            %% Começar verificar sinais amarelos
            %ver sinal amarelo
            if maskYellow == 1 % Se for Mascara Amarela
                filtro = createMaskRedYellowSign(submask); % Aplica um Filtro Vermelho para Detetar os Objetos Vermelhos Dentro do Sinal Amarelo(Filtrar Amarelo e vermelho)
                cc = bwconncomp(filtro); % Bounding Box no Objeto que Detetou

                stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem

                Area = cat(1,stats.Area);
                % Eliminar Objetos Indesejados / Ruído
                [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
                [rw col]= size(stats);

                numObj = cc.NumObjects; % Contagem do Numero de Objetos Detetados
                if numObj ~= 0 % Se Existe Algum Objeto Vermelho(No Caso a Bola Do Semaforo Vermelho)
                    title("Sinal Aviso de Semaforo") % Mostra o Tipo de Sinal
                end

                if numObj == 0
                    filtro = createMaskBlackHSV(submask); %fazer mascara para so pretos
                    cc = bwconncomp(filtro);
                    stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
                    Area = cat(1,stats.Area);
                    % Eliminar Objetos Indesejados / Ruído
                    [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
                    [rw col]= size(stats);
                    numObj = cc.NumObjects;
                    if numObj == 1          %ver obj = 1.
                        title('sinal lomba')
                    elseif numObj > 1       %ver mais que um obj.
                        title('sinal Desvio')
                    end
                end

                %% Começar verificar sinais azuis
            elseif maskBlue == 1 % Se for Mascara Azul
                if isCircle ~= 1 && isSquare == 1 % Se na Mascara Azul o Objeto nao For Redondo (Sinal sem Saida é um Quadrado)
                    title("Sinal Estacionamento") % Mostra o Sinal Estacionamento
                elseif isCircle == 1 && ~isSquare % No Caso de Ser Redondo
                    filterWhite = createMaskWhiteHSV(submask); % Aplicar um Filtro Branco para Extrair os Objetos Brancos Dentro dos Sinais Azuis
                    matrix = strel('square',10);% Matriz para Percorer a Imagem 5x5
                    erodedIm = imerode(filterWhite,matrix); % Imagem Fechada

                    stats =  regionprops(BW2,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem
                    Area = cat(1,stats.Area);

                    % Eliminar Objetos Indesejados / Ruído
                    [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
                    [rw col]= size(stats);

                    ccBlueSign = bwconncomp(erodedIm); %
                    numObj = ccBlueSign.NumObjects; % Retirar o Numero de Objetos Identificados no Interior

                    if numObj == 1 % Caso hajam 3 Objeto
                        title("Sinal Obrigatório Direita") % Mostra Sinal Obrigatório Direita
                    elseif numObj > 1   %se for maior que 1
                        title("Sinal Obrigatório Luzes") % Mostra Sinal Obrigatório Luzes
                        % Melhorar a Imagem
                        for i=1:rw
                            if (i~=index)
                                erodedIm(stats(i).PixelIdxList)= 0; % Remover Todos os Pixeis a Branco das Areas mais Pequenas
                            end
                        end
                        % Dividir a Imagem a Meio para Contar os Pixeis Brancos para
                        % Saber a Orientacao da Seta
                        % figure,imhshow(erodedIm);

                        % %% Falar com o Sampaio
                        % stats =  regionprops(erodedIm,'Centroid'); % Centro do Objeto
                        %
                        % %explicado, linha nos relatorio
                        % middleColumn = floor(stats.Centroid(1)); % Define que o a Linha de Separacao para Contar Pixeis vai a Posicao da Coordenada X do Centroid
                        % leftHalf = floor(nnz(erodedIm(:,1:middleColumn))); % Contar os Pixeis a Esqueda da Coluna Central
                        % rightHalf = floor(nnz(erodedIm(:,middleColumn+1:end))); % Contar os Pixeis a Direita da Coluna Central
                        % if leftHalf > rightHalf % Se Houver mais Pixeis a Esquerda, a Seta Aponta para a Esquerda
                        %     title("Sinal Virar Esquerda") % Display do Sinal
                        % else % Se Houver mais Pixeis a Direita, a Seta Aponta para a Direita
                        %     title("Sinal Virar Direita")% Display do Sinal
                        % end
                    end
                end



                %% Começar verificar sinais vermelhos
            elseif maskRed == 1 % Se for Mascara Vermelha
                filterRed = createMaskRedHSV(submask);
                ccRed = bwconncomp(filterRed);
                stats =  regionprops(filterRed,'PixelIdxList','Area'); % Retirar as Areas de todos os Objetos Detetados na Imagem

                Area = cat(1,stats.Area);
                % Eliminar Objetos Indesejados / Ruído
                [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
                [rw col]= size(stats);
                numObj = ccRed.NumObjects;

                if isCircle == 1 % Se Detetar um Sinal Redondo
                    filterBlack = createMaskBlackHSV(submask); % Aplica Mascara Preta para Detetar os Objetos Dentro
                    ccBlack = bwconncomp(filterBlack); % Bounding Box
                    numObj = ccBlack.NumObjects; % Conta o Numero de Objetos Detetados

                    matrix = strel('square',10);% Matriz para Percorer a Imagem 5x5
                    erodedIm = imerode(filterWhite,matrix); % Imagem Fechada

                    if numObj > 2 % Se Identificar Objetos
                        title('proibido 100km');
                    end
                elseif numObj == 1
                    title('sinal Seta')
                    for i=1:rw
                        if (i~=index)
                            erodedIm(stats(i).PixelIdxList)= 0; % Remover Todos os Pixeis a Branco das Areas mais Pequenas
                        end
                    end
                    stats =  regionprops(erodedIm,'Centroid'); % Centro do Objeto

                    %explicado, linha nos relatorio
                    middleColumn = floor(stats.Centroid(1)); % Define que o a Linha de Separacao para Contar Pixeis vai a Posicao da Coordenada X do Centroid
                    leftHalf = floor(nnz(erodedIm(:,1:middleColumn))); % Contar os Pixeis a Esqueda da Coluna Central
                    rightHalf = floor(nnz(erodedIm(:,middleColumn+1:end))); % Contar os Pixeis a Direita da Coluna Central
                    if leftHalf > rightHalf % Se Houver mais Pixeis a Esquerda, a Seta Aponta para a Esquerda
                        title("Sinal Proibido direita") % Display do Sinal
                    else % Se Houver mais Pixeis a Direita, a Seta Aponta para a Direita
                        title("Sinal Obrigatorio Direita")% Display do Sinal
                    end
                 end

            elseif isTriangle == 1 % Se o Sinal for Triangular
                filterBlack = createMaskBlackHSV(submask); % Aplica um Filtro Preto Para Ler os Objetos do Centro do Sinal
                stats =  regionprops(filterBlack,'PixelIdxList','Area'); %Retira os Dados das Areas dos Ojetos Detetados
                ccBlack = bwconncomp(filterBlack); %

                Area = cat(1,stats.Area);
                % Eliminar Objetos Indesejados / Ruído
                [maxValue,index] = max([stats.Area]); %Guarda o Objeto com a Maior Area
                [rw col]= size(stats);

                numObj = ccBlack.NumObjects; % Conta o Numero de Objetos Detetados
                if numObj == 8 %se detetar objectos
                    title("Sinal Perigo de Passadeira")
                else
                    title("Sinal Perigo Derrocada")
                end
            else
                errordlg('Sem objeto');
            end
            n = n+1; % sair do processamento
    end
end
end