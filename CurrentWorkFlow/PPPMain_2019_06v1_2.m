% script PPPMain_2019_06
% Main script for processing data acquired in NL63445.018.17/OP4DBT : Optimal contact-pressure in DBT
% In summary this script imports [1] dicom data, identifies R_MLO and L_MLO (Left&Right
% MedioLateral-Oblique View) in multiple pressures, [2] Estimates several data measures like Volume and contact area, 
% [3] Estimates Deformation between the pressure levels, [4] Calculates Strain from Estimated Deformation, 
% [5] Outputs various results to Reveal.js format for observer review

% Clearing the workspace: 
clearvars;close all;clc;
% Defining flags
% (1) Import from .dcm or preprocessed [1/2] --- (2) Output of DBT panel Images [1/2/3] 
% (3) Deformation: Exclude/Load_earlier/Calculate[1/2/3] --- (4) Output Deformation imaages [1/2] 
% (5) Strain: Exclude/Load_earlier/Calculate [1/2/3] --- (6) Output Strain images [1/2] 
% (7) Extra Measures: Exclude/Load_earlier/Calculate [1/2/3] (8) Output Extra Measures [1/2]
% (8) Output Reveal.js syntax DataImages DeformationImages StrainImages PressureInfoTables PressureInfoImages ExtraDataImages
Flags = [1 3 1 0 0 0 0 0]; % --> load data from dicom and output panel images in .png
% Set the resolution ---> small for developing ; large for reliable analysis
ExpRes = [256 256 8];                % output size 
% Get monitor screensize for Image Output 
scrsz  = get(0,'ScreenSize'); 
% list image format out puts & animated format out puts
fig_fmt = ['png','svg'];        anim_fmt = ['gif','avi']; % // TODO[AMS add .apng .svg .mpeg .mp4]
% import pressure stats                                   % // TODO add import pressure stats 
%% Define dataPATHS
if ismac 
    WorkPath        = '/Users/andresprengers/matlabwork/SigmaScreening/Full_Flow/';
    WorkFile        = 'PPPMain_2019_06v1_2.m';
    DataPath        = '/Users/andresprengers/Documents/DATA/Mammo/Studie_PPP/2019/2019-07/';
    StoreFigurePath = '/Users/andresprengers/Dropbox/matlabwork/Java_Dre/Blink_Markdown_Preview_Enhanced/2019-07/assets/'; 
    StoreDataPath   = '/Users/andresprengers/Documents/DATA/Mammo/Studie_PPP/2019/2019-07/'; 
    StoreMDPath     = '/Users/andresprengers/Dropbox/matlabwork/Java_Dre/Blink_Markdown_Preview_Enhanced/2019-07/';
else
end

cd(                   DataPath)
M_F_lst             = dir;                                      % Main Folder List
M_F_lst             = M_F_lst(3:end);                           % Removing '.' & '..' from directory list
if strcmp(M_F_lst(1).name,'.DS_Store') ==1                      % if .DSTORE file present remove that too
   M_F_lst = M_F_lst(2:end);
end

return
% for loop over data 
% Import Data from .dcm or earlier stored and preprocessed

M_F_c_range     = 1:numel(M_F_lst);
%%
for ff = M_F_c_range(5:end)        %M_F_c_range
    FolderName     = M_F_lst(ff).name;
    Info           = ImportDicom(DataPath,StoreDataPath,ExpRes,FolderName)
    ExportFigs(      FolderName,ExpRes(3))
    dos(['mv *.png ',StoreFigurePath]) 
    dos(['mv *.svg ',StoreFigurePath]) 
end 
%%

%% 
% TODO   dicomread issues with set 3,5,6,9,10,13
M_F_c_range = 1:numel(M_F_lst);[ 4 7 8 11 ];% [3 4 7 8 11 12] %[3 4 7 8 11:12];
for M_F_c=  M_F_c_range(2:end) %          1:numel(M_F_lst)
    
    cd(fullfile(datapath,M_F_lst(M_F_c).name))
    L_F_lst = dir;                                  % Local Folder List         --> Currently all folders just contain 1 date i.e. 
                                                                                    % i.e. no patients were included more than once     
    cd(L_F_lst(end).name);                          % Now in folder with .dcm files
    
    c_f_lst = dir('*.dcm');                         % Current list of dicom files                                                                                
    spl_lst = cell(numel(c_f_lst),11);             % Filename # of parts is inconsistent, lets hope max is 11
    for ii = 1:numel(c_f_lst) 
        f_name = c_f_lst(ii).name;
        f_parts = strsplit(f_name,'_');
        spl_lst(ii,1:numel(f_parts)) = f_parts;
        
    end
    
    % Now lets sift out if we have good data. This means "volume" sets at
    % MLO direction and two sets of the same breast. 
            
    dim_types = spl_lst(:,8);       ang_types = spl_lst(:,5);   side_types = spl_lst(:,4);
    ind_L_MLO  = find(contains(dim_types,'VOLUME')+contains(ang_types,'MLO')+contains(side_types,'L')==3);        
    ind_R_MLO  = find(contains(dim_types,'VOLUME')+contains(ang_types,'MLO')+contains(side_types,'R')==3);   
    
    % so if we have two of proc_ind_L/R_MLO, it means we can assume two
    % pressures and continue to preprocessing. If 1, we skip, if 3, we stop
    % and review manually what exactly happened here, retake?
    switch numel(ind_L_MLO)
        case 1
            % do nothing 
             fprintf(' Only one data set in L_MLO direction available \n')
        case 2 
            proc_ind_L_MLO = ind_L_MLO;         % Hurray let's analyze
              fprintf([c_f_lst(proc_ind_L_MLO(1)).name,' and ',c_f_lst(proc_ind_L_MLO(2)).name,' will be analyzed \n'])
        case 3 
            % do nothing
            fprintf('Three sets of L_MLO present in folder please delete/rename one of them, or...? \n')
        otherwise 
            % do nothing
            fprintf('zero or more than three sets of L_MLO present in folder  please delete/rename one of them, or...? \n')
    end
    switch numel(ind_R_MLO)
        case 1
            % do nothing 
            fprintf(' Only one data set in L_MLO direction available \n')
        case 2 
            proc_ind_R_MLO = ind_R_MLO;         % Hurray let's analyze
            fprintf([c_f_lst(proc_ind_R_MLO(1)).name,' and ',c_f_lst(proc_ind_R_MLO(2)).name,' will be analyzed \n'])
        case 3 
            % do nothing
            fprintf('Three sets of R_MLO present in folder please delete/rename one of them, or...? \n')
        otherwise 
            % do nothing
            fprintf('Zero or more than three sets of R_MLO present in folder  please delete/rename one of them, or...? \n')
    end  
    %%   Crop, Translate & Downsample -> try later n Full(er) Resolution with The Beast
    fprintf(['Cropping and resampling data in ',M_F_lst(M_F_c).name, '... \n'])
    %    currently the L_MLO set is placed on the _right_ side, in original orientation.
    %    the R_MLO set is place on the _left_ side, in original orientation
    %  there is intermediate flipping but this is done  for equal cropping
    % PROCOPT: Images are cropped individually for maximum zoom to image. Drawback is left and right can  differ in relative size
    un_proc_siz = [1000,1000,80];
    MxSets = max([numel(ind_R_MLO), numel(ind_L_MLO)]); % i.eif number of pressure sets are uneven, we create matrix with 2x max no of sets so we 
    % can display a panel with left or right empty

    un_proc_dat                                     =  zeros(un_proc_siz(1),un_proc_siz(2),ppsize(3),max([numel(ind_R_MLO), numel(ind_L_MLO)])*2);          % size large enough to contain all data and 4 sets
    un_proc_bin                                     =  zeros(size(un_proc_dat));                                  % store P1-P2 % R/L_MLO along same dim   R_MLO in 1&2 ; L_MLO in 3&4
    if exist('proc_ind_L_MLO','var')                == 1                                                          % for memory purposes and symmetrical cropping
        for ii                                      =  1:numel(proc_ind_L_MLO)                                    % looping over pressures 1&2
            f_name                                  =  c_f_lst(proc_ind_L_MLO(ii)).name;
            datR                                    =  squeeze(dicomread(f_name));
            datRsiz                                 =  size(datR);
            un_proc_dat(:,:,:,ii+MxSets)            =  flip(imresize3(datR,[un_proc_siz(1) un_proc_siz(2) ppsize(3)]),2); % default option of imresize is bicubic
            % please note, for third dimension we go straight to ppsize i.e. the final output size  as there will be no cropping and flipping occuring in that dimension
            un_proc_bin(:,:,:,ii+MxSets)            =  imbinarize(un_proc_dat(:,:,:,ii)); % default option of imresize is bicubic
        end
    end
    if exist('proc_ind_R_MLO','var')                == 1                            %
        for ii                                      =  1:numel(proc_ind_R_MLO)
            f_name                                  =  c_f_lst(proc_ind_R_MLO(ii)).name;
            datR                                    =  squeeze(dicomread(f_name));
            datRsiz                                 =  size(datR);
            un_proc_dat(:,:,:,ii)                   =  imresize3(datR,[un_proc_siz(1) un_proc_siz(2) ppsize(3)]); % default option of imresize is bicubic
            % please note, for third dimension we go straight to ppsize i.e. the final output size  as there will be no cropping and flipping occuring in that dimension
            un_proc_bin(:,:,:,ii)                   =  imbinarize(un_proc_dat(:,:,:,ii));
        end
    end
    L_index          = find(un_proc_bin);[I,J,K,L] = ind2sub([size(un_proc_dat,1) size(un_proc_dat,2) size(un_proc_dat,3) size(un_proc_dat,4)],L_index);
    bound_L          = [min(I(:)) max(I(:)) min(J(:)) max(J(:)) min(K(:)) max(K(:)) min(L(:)) max(L(:))];
    crop_un_proc_dat = un_proc_dat(bound_L(1):bound_L(2), bound_L(3):bound_L(4),bound_L(5):bound_L(6),:);
    pre_proc_dat     = padarray(crop_un_proc_dat,[1 1 0 0],'both'); % padd aray is to keep several algorithms from running into trouble when data is on the outer rim of bounding box
    dat              = zeros([ppsize(1) ppsize(2) ppsize(3) MxSets*2]);
 %   if exist('proc_ind_R_MLO','var') == 1 && exist('proc_ind_L_MLO','var') == 1
        for ii = 1:MxSets*2
            dat(:,:,:,ii) = imresize3(pre_proc_dat(:,:,:,ii),[ppsize(1) ppsize(2) ppsize(3)]);  % bicubic interp to ppsize
        end
  %  end
    dat              = dat/max(dat(:));
    clear              datR un_proc_dat un_proc_bin crop_un_proc_dat;    % free up space
    Sz               = size(dat); % out_put_size just checking;
    % pre_proc_dat --> pre-processed data; dim(1,2,3)=[r,c,s] | dim 4 -->
    % [Pressure_1_left Pressure_2_left Pressure_1_right Pressure_2_right
    D                = zeros(Sz(1),Sz(2),Sz(3),3); % Displacement x-y-z
    S                = zeros(Sz(1),Sz(2),Sz(3),5); % Strain x-y-z-summed strain- shear strain - diagonal strain
    %
    % TODO: add strain tensor output in various representations
    
     %% Strain estimation based on Myrenko's toolbox
     % Main settings
%   
%         for ppp = 1:MxSets
%             [D,S] = NR_Myronenko2D(dat(:,:,:,(pp-1)*2+1),dat(:,:,:,(pp-1)*2+2),'ssd','No');
%             DD = squeeze(sum(D,4));DD = DD/max(DD(:));
%             SS = squeeze(sum(S,4));SS = SS/max(SS(:));
%             close all;
%             for ii = 1:ppsize(3)
%             f=figure;imagesc(BlIm);colormap gray;axis off;
%             set(f,'Position',[scrsz(1) scrsz(2) 0.75*scrsz(3) 0.75*scrsz(4)])             %
%             export_fig(gcf,f_label,['-',fig_fmt],'-c[NaN,NaN,NaN,NaN]','-transparent','-r300');
%             dos(['mv *.',fig_fmt,' ',store_fig_path])
%             fprintf(['Exported Strain & Deformation in slice ',num2str(iii),' Pressure ',num2str(ppp), ' in ',M_F_lst(M_F_c).name,'... \n'])
%             end
%         end
%    
%     
% return
    %% Export initial images for Markdown
    
    %  ii = 1-->R_MLO-P1 ii=2-->R_MLO-P2 ii=3-->L_MLO-P1 ii=4-->L_MLO-P2
    % we need to loop over folders >> slices >> pressures >> sides
    close all;
 %   return
    %fileID = fopen([store_path,'/input2Markdown7.txt'],'w');
    ct_str = 73; % cut off string --. cutoff '/Users/andresprengers/Dropbox/PostdocMammo/DATA/Studie_PPP/2019/2019-06/'
    % TODO Put applied pressures in string output to Reveal.js
    % TODO Options for Inverting the Image contrast (can be done by creating separate images or in -js im processing --> _which is faster_
    % TODO add [zoom.js](https://lab.hakim.se/zoom-js/)
    % TODO add annotation; markers, text... [option1](http://annotatorjs.org/)
    % TODO annotation 2 [option2](https://www.npmjs.com/package/annotation-js) [option3](https://github.com/instructure/pdf-annotate.js/)
    % TODO annotation 3 [option4](https://github.com/chartjs/chartjs-plugin-annotation)
    % TODO findout/add multiline TODO reporting
    % Define static string --- Pressure input string --- reveal.js slide string
    
    for iii =[1 4 8]%:ppsize(3)                                    % loop over slices
        for ppp = 1:MxSets                                       % loop over pressures
            if exist('proc_ind_L_MLO','var')                == 1  % if yes get the image
                LPim = dat(:,:,iii,ppp+MxSets);             % left panel of blink image
            else
                LPim = zeros(Sz(1),Sz(2));        % blank canvas as left panel
            end
            if exist('proc_ind_R_MLO','var')                == 1  % if yes get the image
                RPim = flip(dat(:,:,iii,ppp),2);                  % right panel of blink image   -- flipping back to
            else
                RPim = zeros(Sz(1),Sz(2));           % blank canvas as right panel
            end
            BlIm = cat(2,LPim,RPim);
            f_label = [char(M_F_lst(M_F_c).name),...                      %
                '_slice_',getprefix(iii,10),num2str(iii),'_P_',num2str(ppp)];
            close all;
            f=figure;imagesc(BlIm);colormap gray;axis off;
            set(f,'Position',[scrsz(1) scrsz(2) 0.75*scrsz(3) 0.75*scrsz(4)])             %
            export_fig(gcf,f_label,['-',fig_fmt],'-c[NaN,NaN,NaN,NaN]','-transparent','-r300');
            dos(['mv *.',fig_fmt,' ',store_fig_path])
            fprintf(['Exported slice ',num2str(iii),' Pressure ',num2str(ppp), ' in ',M_F_lst(M_F_c).name,'... \n'])
        end
    end
    %%
    
    %%
    
    

end
return
fprintf(fileID,charTODOS('TODO','/Users/andresprengers/Dropbox/matlabwork/SigmaScreening/Full_Flow/','subdirs'));
 TODOS({'TODO','IDEA','OPT'},[workpath,workfile],'file');
%fclose(fileID)
%% Create Markdown Input file for all datasets
txt_output = 'input2Markdown06.md';
    dos(['rm ',store_path,'/',txt_output]);
    front_matter_string = ['--- \n ',...
        'presentation: \n ',...
        'enableSpeakerNotes: true \n ',...
        'width: "100%%" \n',...
        'height: "100%%" \n',...
        'transition: none \n',...
        'background-transition: none \n ',...
        '--- \n ',...
        '<!-- slide --> \n ',...
        '# Strain Analysis of: \n ',...
        '# Data :  \n',...
        '# use cursor keys for moving \n ',...
        '# more info can be added here \n ' ,...
        '<!-- slide --> \n'];
    fid=fopen([store_path,'/',txt_output],'a+');fprintf(fid,front_matter_string);fclose(fid);  
%    cell2txtfile([store_path,'/',txt_output],front_matter_string,'a')
%     st_str = {'Data: ____ ';char(['slice: ____ of ',char(num2str(ppsize(3))), ' Applied Pressure: ']); ...
%         '____ kPa';' (____) ';['@import " ims2/____.',char(fig_fmt),'"'];' {width="100%" height="100%"} ';...
%         '____'}; % make sure there are as many cell elements as replace makers for strrep to work!! 
%    % strings to iput: 1 DATA 2 Slicenumber 3 FirstOrSecond 4 FileName 5 MarkdownSlide
   % st_str = {'Data: ', ' slice: ',[' of ',num2str(ppsize(3))], ' Applied Pressure:', 'kPa ',...
   %     '@import  " ims2/',['.',fig_fmt,'" {width="100%" height="100%"} ']};
    p_str  = {' --> Primary',' --> Secondary'};
    sl_str = {'<!-- slide vertical=true data-transition=none-->','<!-- slide vertical=false data-transition=none -->'};
  %  return
st_str = ['  Data: PRINT_DAT \n',... 
'slice: SLIC_NUM of ',num2str(ppsize(3)),'\n Applied Pressure: ',... 
'____  kPa  ( --> F_S) \n',... 
'@import " ims2/14F8565A_slice_01.png"',...
' {width="100%%" height="100%%"} \n <!-- slide vertical=true-->'];
  
  M_F_c_range =  [ 4 7 8 11 ]
for M_F_c=  M_F_c_range % 
    %M_F_c
    cd(fullfile(datapath,M_F_lst(M_F_c).name))
    L_F_lst = dir;                                  % Local Folder List         --> Currently all folders just contain 1 date i.e. 
                                                                                    % i.e. no patients were included more than once     
    cd(L_F_lst(end).name);                          % Now in folder with .dcm files
    for iii =1:ppsize(3)                                    % loop over slices
        for ppp = 1:MxSets                                       % loop over pressures
            f_label = char(M_F_lst(M_F_c).name);
            tot_str = ['  Data: ',f_label,'<br> \n',... 
            'slice: ',getprefix(iii,10),num2str(iii),' of ',getprefix(iii,10),num2str(ppsize(3)),'<br> \n',...
            'Applied Pressure: ____  kPa  (',p_str(floor(ppp/2)+1),') <br> \n',... 
            '@import " ims2/',M_F_lst(M_F_c).name,'_slice_',getprefix(iii,10),num2str(iii),'_P_',num2str(ppp),'.',fig_fmt,'" {width="100%%" height="100%%"} \n',...
            sl_str(floor(ppp/2)+1),' \n'];
            cell2txtfile([store_path,'/',txt_output],tot_str,'a');
        end
    end
end

fprintf('Finished!!');

% 01--> Calculate array of similarity indexes between pre_proc_dat(:,:,:,1) to
% pre_proc_dat(:,:,:,2) and pre_proc_dat(:,:,:,3) to pre_proc_dat(:,:,:,4)

% 02 --> Find Scale Invariant Robust Features (SURF) in 3D
% 03 --> Transform pre_proc_dat(:,:,:,2) to pre_proc_dat(:,:,:,1) and pre_proc_dat(:,:,:,4) to pre_proc_dat(:,:,:,3)
% 04 --> ReCalculate array of similarity indexes
% 05 --> Run Myrenenko's non rigid image Registration (soooo many tuning factors) 
% 06 --> ReCalculate array of similarity indexes
% 07 --> Add Optical flow  --> Horn Schunk is probably better, but there are
% also combined methods  (see last tab ouliner web page)
% 08 --> Explain in MPE how you're trying to optimize this chain (almost as a DL network (use graphViz Dot Chart))
% 09 --> Convert to Ard's preffered data config
% 10 --> Calculate several strain measures 
% 11 --> Displacement maps independently, also with alpha propotrional to  Displacement
% 12 --> Strain maps independently, also with alpha propotrional to strain magnitude over original data
% 13 --> Bargraphs of Displacement and Strain and P1 P2 (to be left open) 


% --- Shepp Logan 
% 
