% short_line_pf.m
% Short transmission line (per-phase model) feeding an inductive load,
% before and after power factor correction with a capacitor bank.
%
% Short-line model: series impedance Z = R + jX only (no shunt capacitance).
%   Vs = Vr + I*Z
%   %VR = (|Vs| - |Vr|) / |Vr| * 100      (for a short line, no-load Vr = Vs)

clear; clc;

%% 1. System data (example values - state them in your README)
f      = 50;              % Hz
VLL    = 33e3;            % receiving-end line-to-line voltage (V), held constant
P3     = 10e6;            % 3-phase load real power (W)
pf1    = 0.80;            % load power factor, lagging (inductive)
pf2    = 0.95;            % target power factor after correction
Z      = 2 + 1j*6;        % line impedance per phase (ohm): R = 2, X = 6

%% 2. Per-phase quantities (reference phasor: Vr at 0 degrees)
Vr = VLL/sqrt(3);         % phase voltage
P  = P3/3;                % real power per phase

%% 3. Before correction
th1 = acos(pf1);
Q1  = P*tan(th1);                       % reactive power per phase (VAr)
I1  = P/(Vr*pf1) * exp(-1j*th1);        % lagging current: angle = -theta
Vs1 = Vr + I1*Z;
VR1 = (abs(Vs1)-abs(Vr))/abs(Vr)*100;
Loss1 = 3*abs(I1)^2*real(Z);            % total 3-phase line loss (W)

%% 4. Capacitor bank needed to raise pf from pf1 to pf2
th2 = acos(pf2);
Qc  = P*(tan(th1) - tan(th2));          % VAr per phase to be supplied by capacitors
C   = Qc/(2*pi*f*Vr^2);                 % per-phase capacitance (F), Qc = w*C*Vr^2

%% 5. After correction (same real power, less reactive power drawn through the line)
I2  = P/(Vr*pf2) * exp(-1j*th2);
Vs2 = Vr + I2*Z;
VR2 = (abs(Vs2)-abs(Vr))/abs(Vr)*100;
Loss2 = 3*abs(I2)^2*real(Z);

%% 6. Results
fprintf('                         Before     After\n');
fprintf('Power factor            %7.2f   %7.2f\n', pf1, pf2);
fprintf('Line current (A)        %7.1f   %7.1f\n', abs(I1), abs(I2));
fprintf('Sending voltage (kV LL) %7.2f   %7.2f\n', sqrt(3)*abs(Vs1)/1e3, sqrt(3)*abs(Vs2)/1e3);
fprintf('Voltage regulation (%%)  %7.2f   %7.2f\n', VR1, VR2);
fprintf('Line loss (kW)          %7.1f   %7.1f\n', Loss1/1e3, Loss2/1e3);
fprintf('Capacitor bank: %.2f MVAr total (%.1f uF per phase)\n', 3*Qc/1e6, C*1e6);
fprintf('Loss reduction: %.1f %%\n', (Loss1-Loss2)/Loss1*100);
