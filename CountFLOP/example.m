clear
clc

%% Example 1: MATLAB Scripts
profile on
exampleScript
profileStruct = profile('info');
[flopTotal,Details]  = FLOPS('exampleScript','exampleScriptMAT',profileStruct);

%%
pause(5)

%% Example 2: MATLAB Functions
X = randn(100,3); Y = (X*[1 2 3]'+randn(100,1))>0;
profile on
[Beta_draws,ME1,ME2] = exampleFun(Y,X);
profileStruct = profile('info');
[flopTotal,Details] = FLOPS('exampleFun','exampleFunMat',profileStruct);

%%
pause(5)

%% Convenient but risky way to use this program: MATLAB Scripts
FLOPS('exampleScript');

%%
pause(5)

%% Convenient but risky way to use this program: MATLAB Functions
X = randn(100,3); Y = (X*[1 2 3]'+randn(100,1))>0;
FLOPS('exampleFun(Y,X)');

