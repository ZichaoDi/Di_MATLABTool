%clear;

path(path,'../MAT')

%%%%%%%%%%%%%%%%%%% Convergence plot %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[cum_comp_mgv1, cost_mgv1, k_mgv1]=costparse('OUTPUT');
[cum_comp_1, cost_1, k_1]=costparse('fixed_grid/REFERENCE_RESULTS');
figure(19);
set(0,'defaultaxesfontsize',16);
h=plot(cum_comp_mgv1(1:k_mgv1), cost_mgv1(1:k_mgv1), 'b-',cum_comp_1(1:k_mgv1),cost_1(1:k_mgv1),'ro-');
hleg=legend('adaptive mgv', 'fixed-grid');  
set(hleg,'FontSize',16);
xlabel('Iterations (converted to finest grid iterations)');
ylabel('Cost');
set(h,'LineWidth',2);
% axis([0 40 -42000 -16000]);
set(gca,'Position',[.23 .21 .675 .715]);
%print -deps cost.eps


%%%%%%%%%%% Surface plots for every other cross-sections %%%%%%%%%%%%

fid=datOpen('OUTPUT/muhat011_4_1.dat','r'); 
fid_1=datOpen('fixed_grid/REFERENCE_RESULTS/muhat000_1_499.dat','r'); 
dims=[2 33 33 33]; 
[status, data]=read_float_array(fid, 'rec', length(dims), dims); 
[status, data1]=read_float_array(fid_1, 'rec', length(dims), dims); 
fclose(fid);
fclose(fid_1);

figure,
plotzz(shiftdim(data(1,:,:,:)),1); 
figure,
plotzz(shiftdim(data1(1,:,:,:)),1); 

return

