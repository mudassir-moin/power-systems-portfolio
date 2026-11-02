% build_ybus.m
% Builds the bus admittance matrix (Ybus) for a 3-bus network, all values in per-unit.
% Then uses I = Ybus * V to find the current injected at each bus.

clear; clc;

%% 1. Line data: [from_bus, to_bus, R, X]  (p.u.)
lines = [ 1 2 0.020 0.080;
          2 3 0.010 0.040;
          1 3 0.015 0.060 ];

nbus = 3;
nline = size(lines, 1);

%% 2. Series impedance -> admittance:  y = 1/z = 1/(R + jX)
from = lines(:,1);
to   = lines(:,2);
z    = lines(:,3) + 1j*lines(:,4);
y    = 1 ./ z;

%% 3. Assemble Ybus
%   off-diagonal:  Y(i,j) = -y_ij      (minus the admittance of the line joining i and j)
%   diagonal:      Y(i,i) = sum of the admittances of all lines connected to bus i
Ybus = zeros(nbus, nbus);
for k = 1:nline
    i = from(k);  j = to(k);
    Ybus(i,i) = Ybus(i,i) + y(k);
    Ybus(j,j) = Ybus(j,j) + y(k);
    Ybus(i,j) = Ybus(i,j) - y(k);
    Ybus(j,i) = Ybus(j,i) - y(k);
end

disp('Ybus (p.u.) ='); disp(Ybus);

%% 4. Sanity checks
% With no shunt elements, every row of Ybus must sum to zero
% (no current "leaks" to ground), and Ybus must be symmetric.
fprintf('Max |row sum|      : %.2e  (should be ~0)\n', max(abs(sum(Ybus, 2))));
fprintf('Max |Y - Y.''|      : %.2e  (should be 0)\n', max(max(abs(Ybus - Ybus.'))));

%% 5. Nodal currents from bus voltages:  I = Ybus * V
V = [1.00*exp(1j*0); 0.98*exp(-1j*deg2rad(2)); 0.97*exp(-1j*deg2rad(3))];  % example voltages (p.u.)
I = Ybus * V;

disp('Injected bus currents I = Ybus*V (p.u.):'); disp(I);
fprintf('Sum of currents (should be ~0): %.2e\n', abs(sum(I)));
