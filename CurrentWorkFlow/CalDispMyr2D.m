function [Displacement,Settings] = CalDispMyr2D(Name,export,zdim)
% Strain:2D strain i.e. (1stD,2ndD,2,2)-tensor SDNStrain: Summed-Demeaned-Normalized-Strain 2D-matrix
% Displacement estimated using Myrenenko 2D non ridid registration
% ImCheck --> im2 warped to im1 using registration results
% //TODO AMS[script CalDisMyr2D remove SDNStrain and export into single function; will save space];
main.similarity     ='ssd';                     % similarity measure, e.g. SSD, CC, SAD, RC, CD2, MS, MI 
main.subdivide      = 3;                        % use 3 hierarchical levels
main.okno           = 3;                        % mesh window size
main.lambda         = 0.005;                    % transformation regularization weight, 0 for none
main.single         = 0;                        % show mesh transformation at every iteration
% Optimization settings
optim.maxsteps      = 50;                       % maximum number of iterations at each hierarchical level
optim.fundif        = 1e-5;                     % tolerance (stopping criterion)
optim.gamma         = 1;                        % initial optimization step size 
optim.anneal        = 0.8;                      % annealing rate on the optimization step    
Settings.main       = main;
Settings.optim      = optim; 
ImTypes             = {'MLO','CC'};
ImSides             = {'R','L'};
ImsMLO              = niftiread([Name,'_',char(ImTypes(1)),'_',char(ImSides(1)),'_',char(ImSides(2)),'.nii']);
siz                 = size(ImsMLO);             % ImsMLO --->  four stacks in z_dir: R_MLO P1 --- R_MLO P2 --- L_MLO P1 --- L_MLO P2
ImsMLO              = mat2gray(ImsMLO); 
Displacement        = zeros(siz(1),siz(2),2*zdim,2);
%Strain              = zeros(siz(1),siz(2),2*zdim,2,2);
%SDNStrain           = zeros(siz(1),siz(2),2*zdim);
ImCheck             = zeros(siz(1),siz(2),zdim,2);
Mask                = zeros(siz(1),siz(2),2*zdim);
    for ImSide = 1:numel(ImSides)
        for n = 1:zdim
            n1                              =  n+(ImSide-1)*zdim;
            n2                              =  n1+zdim;
            im1                             =  ImsMLO(:,:,n1);
            im2                             =  ImsMLO(:,:,n2);
            imbin                           =  logical(imbinarize(im1)+imbinarize(im2));
            Mask(                              :,:,n1)=imbin;
            % AMJ --> added 'M_total_struct' to output and 'ExportIm' to input for image output
            [res, newim]                    =  mirt2D_register(im1,im2, main, optim, export);
            ImCheck(:,:,n1,ImSide)          =  newim;
            F                               =  mirt2D_F(res.okno);
            [Xx,Xy]                         =  mirt2D_nodes2grid(res.X, F, res.okno);
            [Xgrid,Ygrid]                   =  mirt2D_nodes2grid(res.Xgrid,F,res.okno);
            Disp                            =  zeros(siz(1),siz(2),2);
            RDisp                           =  cat(3,Xx-Xgrid,Xy-Ygrid); 
            [M,N]                           =  size(Xx);
            Disp(                              1:min(siz(1),M),1:min(siz(2),N),:)...
                                            =  RDisp(1:min(siz(1),M),1:min(siz(2),N),:);
            if strcmp(export,'ExportIms')   == 1
               figure(1);subplot(1,3,3,'align'); 
               mirt2D_meshplot(res.X(:,:,1),res.X(:,:,2));
               GIFit([],0.1,[Name,'_SSDreg_LMLO_slice',num2str(n)],[]);
               AVIit([],0.1,[Name,'_SSDreg_LMLO_slice',num2str(n)],[]);
            end
            %StrainField                     = strain(Xx,Xy);
            %for ii = 1:2 
            %    for jj = 1:2 
            %        Strain(:,:,n1,ii,jj)    = imbin.*imresize(StrainField(:,:,ii,jj),[siz(1) siz(2)]); 
            %    end
            %end
             Displacement(:,:,n1,:)          = permute(Disp.*cat(3,imbin,imbin),[1 2 4 3]);
        end
    end
    wr_str              = [Name,'_Displacement'];
    niftiwrite(           Displacement,wr_str);
    Info                = niftiinfo([wr_str,'.nii']);
  %  hdr.Info           = Info;
    Info.res            = res ;
    Info.main           = main;
    Info.optim          = optim;
    Info.readme         = 'Original DicomHeader is in Imfo, .main and .optim contains Estimation settings, .res contains format info of output (i.e. Displacement)';
    niftiwrite(           Displacement,wr_str,Info);
    niftiwrite(           Mask,[Name,'_Mask.nii']);    

end