%使用类似异重流流速分布曲线形式的公式拟合切应力分布
% 假设您的数据已经以表格形式导入，命名为 data
% 分离数据
load('data_smaller_than_Bw.mat');
Da = data(:,1);
pis = data(:, 2:5);
tau = data(:,6);
zp = data(:, 7);

% 定义目标函数，用于优化 exps 和 coef
objectiveFunction = @(parameters) optimizeRelativeShear(parameters, Da, pis, tau, zp);

% 初始参数猜测
exps_ini = [-1.295, 0.026, 0.221, -1.062];
coef_ini = 0.025;
aofx_ini = 1;
initialGuess = [exps_ini, coef_ini, aofx_ini];
A = [-1, 0, 0, 0, 0, 0; 1, 0, 0, 0, 0, 0; 0, 1, 0, 0, 0, 0; 0, -1, 0, 0, 0, 0; 0, 0, 1, 0, 0, 0; 0, 0, -1, 0, 0, 0; 0, 0, 0, 1, 0, 0; 0, 0, 0, 0, 1, 0];      %限制参数的搜索范围
b = [3; 0; 0.1; 0; 1; 0; 1; 10];        %被限制参数的允许最大值

% 进行优化（使用 MATLAB 优化工具箱中的函数，如 fmincon）
optimizedParameters = fmincon(objectiveFunction, initialGuess, A, b);

% 优化后的 exps 和 coef
optimizedExps = optimizedParameters(1:4);
optimizedCoef = optimizedParameters(5);
optimizedAofx = optimizedParameters(6);

% 使用优化后的参数计算 tauRel
tauRelOptimized = RelativeShear(Da, pis, tau, optimizedExps, optimizedCoef);

% 模型评估
% 计算 R? 或其他统计指标
y = linspace(0.001, max(zp), 200);
y = y.';
yp = y.^optimizedAofx./(y.^optimizedAofx+1);

zpp = zp.^optimizedAofx./(zp.^optimizedAofx+1);
options = optimoptions('lsqcurvefit','Algorithm','trust-region-reflective');
[a,~,~,exitflag,output] = lsqcurvefit(@tau_distribution, [0.6; 2.2], zpp, tauRelOptimized, [0;0], [Inf;Inf], options);
x=tau_distribution(a, yp);


plot(tauRelOptimized,zp,'ro');
hold on;
plot(x, y);

% 函数定义
function cost = optimizeRelativeShear(parameters, Da, pis, tau, zp)
    exps = parameters(1:4);
    coef = parameters(5);
    aofx = parameters(6);
    tauRelCalculated = RelativeShear(Da, pis, tau, exps, coef);
    
    % 这里需要定义一个合适的预测模型
    
    zpp = zp.^aofx./(zp.^aofx+1);       %把zp映射到(0, 1)区间
    options = optimoptions('lsqcurvefit','Algorithm','trust-region-reflective');
    [a,~,~,exitflag,output] = lsqcurvefit(@tau_distribution, [0.6; 2.2], zpp, tauRelCalculated, [0;0], [Inf;10], options);
    
    tauRelPredicted=tau_distribution(a, zpp);

    % 计算成本（比如均方误差）
    cost = mean((tauRelCalculated - tauRelPredicted).^2);
end


function [tau_tauMax]=tau_distribution(a, eta)

m = a(1);
n = a(2);
sigma=(m+n)^(m+n)/m^m/n^n;

tau_tauMax=sigma*eta.^m.*(1-eta).^n;
end