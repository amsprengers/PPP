function [D,Settings] = DCalDispMyr2D(FolderName,export)

main.similarity='ssd';  % similarity measure, e.g. SSD, CC, SAD, RC, CD2, MS, MI 
main.subdivide=3;       % use 3 hierarchical levels
main.okno=3;            % mesh window size
main.lambda = 0.005;    % transformation regularization weight, 0 for none
main.single=0;          % show mesh transformation at every iteration

% Optimization settings
optim.maxsteps = 50;    % maximum number of iterations at each hierarchical level
optim.fundif = 1e-5;    % tolerance (stopping criterion)
optim.gamma = 1;        % initial optimization step size 
optim.anneal=0.8;       % annealing rate on the optimization step    

V = niftiread([FolderName,'.nii']);



for n = 1:size(im1,3)
% AMJ --> added 'M_total_struct' to output and 'ExportIm' to input for image output
[res, newim]    =   mirt2D_register(im1(:,:,n),im2(:,:,n), main, optim, export);
F                               =   mirt2D_F(res.okno);
[Xx,Xy]                         =   mirt2D_nodes2grid(res.X, F, res.okno);
% just in case it's ~2 pixels of in size
%Xx                              =  imresize(Xx,[size(im1,1) size(im1,2)]);
%Xy                              =  imresize(Xy,[size(im1,1) size(im1,2)]);
figure(1); h =  subplot(1,3,3,'align'); mirt2D_meshplot(res.X(:,:,1),res.X(:,:,2));
% N_pngs = numel(dir('*.png'));
%Xd = Xx-xx;
%Yd = Xy-yy; % --> WE REALLY NEED TO RECHECK
% There is some sort of offset but gradient in strain calc should kill it
StrainField = strain(Xx,Xy); 
  Dig_strain = squeeze(sum(sum(StrainField,4),3));
  Dig_strain = Dig_strain - mean(Dig_strain);
  Dig_strain = Dig_strain/max(abs(Dig_strain(:)));
  Dig_strain = imresize(Dig_strain,[size(ALLstrain,1) size(ALLstrain,2)]);
  Dig_strain = Dig_strain.*imbinarize(im1(:,:,n)).*imbinarize(im2(:,:,n));
  ALLstrain(:,:,n,1) = Dig_strain;
  if strcmp(export,'ExportIms')==1
  GIFit([],0.1,[storepath,set_Name,'_SSDreg_LMLO_slice',num2str(n)],[]);
  AVIit([],0.1,[storepath,set_Name,'_SSDreg_LMLO_slice',num2str(n)],[]);
  dos('rm *.png');
  end
end
