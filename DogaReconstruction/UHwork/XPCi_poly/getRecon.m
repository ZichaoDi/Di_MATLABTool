function out = getRecon(pars,out,obj,e)

global constant

% anchored energy
energy = getEnergyPar(e);

obj = calcObj(obj,energy);
proj = calcProj(energy,pars,obj); 

out.absTrue = 4*pi./energy.lambda.*proj.beta;
out.absCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*out.intRhoZ;
out.phiTrue = energy.k*proj.delta;
out.phiCalc = 2*pi*constant.re/energy.k*out.intRho;
out.muTrue = proj.mu;
out.muCalc = 4*sqrt(2)*constant.a^4*constant.sigmaT/energy.E^3.4*out.intRhoZ+energy.sigmaC.*out.intRho;
out.scaTrue = energy.sigmaC.*energy.k.^2./(2*pi*constant.re).*proj.delta;

end
