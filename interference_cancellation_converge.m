clear;
L = 2;
M = 100;
K = 100;
SNRdB = 0;
numCases = 100;
T = 3;

SNR = 10^(SNRdB / 10);
N0 = 1 / SNR;

BSs = zeros(L, 1);
r = 2;
if L == 1
    BSs = 0;
elseif L == 2
    BSs = [0, r * 1j];
elseif L == 3
    BSs = [0, r * 1j, r * cos(pi / 6) + r * sin(pi / 6) * 1j];
elseif L == 4
    BSs = [0, ...
                r * 1j, ...
                r * cos(pi / 6) + r * sin(pi / 6) * 1j, ...
                -r * cos(pi / 6) + r * sin(pi / 6) * 1j];
    F = [1, 2, 3, 3];
elseif L == 7
    BSs = [0, ...
                r * 1j, ...
                r * cos(pi / 6) + r * sin(pi / 6) * 1j, ...
                -r * cos(pi / 6) + r * sin(pi / 6) * 1j, ...
                r * cos(pi / 6) + r * (sin(pi / 6) - 1) * 1j, ...
                -r * 1j, ...
                -r * cos(pi / 6) + r * (sin(pi / 6) - 1) * 1j];
    F = [1, 2, 3, 3, 2, 3, 2];
end

err = 0;
simus = zeros((T + 1) * L, numCases);
calcs = zeros((T + 1) * L, numCases);

for ci = 1 : numCases
    UEs = brownian(L, K, BSs, r / sqrt(3));
    [R, P] = generateReceiveCorrelation(L, M, K, BSs, UEs);
    H = generateMIMOChannel(L, M, BSs, K, UEs, R);
    xr = (randi([0, 1], L * K, 1) * 2 - 1) / sqrt(2);
    xi = (randi([0, 1], L * K, 1) * 2 - 1) / sqrt(2);
    x = xr + xi * 1j;
    y = H * x + (randn(L * M, 1) + randn(L * M, 1) * 1j) / sqrt(2) * sqrt(N0);

    %xhat = pinv(H) * y;
    %xhat = H' / (H * H' + N0 * eye(M)) * y;

    [xhat, simu, calc] = iterative_cancellation_converge(L, M, K, H, y, N0, x, T);
    simus(:, ci) = simu;
    calcs(:, ci) = calc;

    %[A, cost, main, cros] = pilot_assignment(L, M, K, R, N0);
    %[Hhat, C] = channel_estimate(L, M, K, H, R, A, N0);
    %xhat = iterative_cancellation_imperfect(L, M, K, Hhat, C, y, N0, 2);
    err = err + sum(real(x) .* real(xhat) < 0) + sum(imag(x) .* imag(xhat) < 0);
end

asimu = mean(simus, 2);
acalc = mean(calcs, 2);

fprintf(2, 'BER is %e, with %d errors\n', err / numCases / L / K / 2, err);
