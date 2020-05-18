%% sgr_iso
% Gets specific population growth rate

%%
function [r info tb tp_out lb lp_out uE0] = sgr_iso (p, f)
  % created 2009/09/15 by Bas Kooijman, modified 2011/04/26
  
  %% Syntax
  % [r info tb tp_out lb lp_out uE0] = <../sgr_iso.m *sgr_iso*> (p, f)
  
  %% Description
  % Specific population growth rate for reproducing isomorphs;
  % The embryonic stage is excluded; aging is the only cause of death. 
  % Food density is assumed to be constant.
  %
  % Input
  %
  % * p: 11-vector with parameters: kap kapR g kJ kM LT v UHb UHp ha sG
  % * F: optional scalar with scaled function response (default 1)
  %
  % Output
  %
  % * r: scalar with specific population growth rate
  %    1 = \int_0^infty S(t) R(t) exp(- r t) dt
  % * info: scalar with indicator for failure (0) or success (1) or large tm (2)
  % * tb: scalar with scaled age at birth ab/kM 
  % * tp_out: scalar with scaled age at puberty ap/kM 
  % * lb: scalar with scaled length at birth
  % * lp_out: scalar with scaled length at puberty
  % * uE0: scalar with scaled initial reserve
  
  %% Remarks
  % See <ssd_iso.html *ssd_iso*> for mean age, length, squared length, cubed length.
  % See <f_ris0.html *f_ris0*> for f at which r = 0
  
  %% Example of use
  % [r info tb tp lb lp uE0] = sgr_iso([0.8 0.95 0.1 0.002 0.02 0 0.02 1 5 1e-7 1e-8])

  % unpack parameters
  kap = p(1); kapR = p(2); g   = p(3); 
  kJ  = p(4); kM   = p(5); LT  = p(6);  
  v   = p(7); UHb  = p(8); UHp = p(9);
  ha = p(10); sG = p(11);

  if ~exist('f','var')
    f = 1;
  end

  k = kJ/ kM;
  Lm = v/ g/ kM;
  lT = LT/ Lm;
  li = f - lT;
  VHb = UHb/ (1 - kap); VHp = UHp/ (1 - kap);
  vHb = VHb * g^2 * kM^3/ v^2; vHp = VHp * g^2 * kM^3/ v^2;
  rhoB = 1/(3 + 3 * f/g); % rB/ kM
  hW = (ha * g/ 6/ kM^2)^(1/3); % hW/ kM
  hG = sG * g * f^3; % hG/ kM
  hWG3 = (hW/ hG)^3;
  pars_tm = [g; k; lT; vHb; vHp; ha/ kM^2; sG]; % compose parameter vector
  tm = get_tm_s(pars_tm, f);                    % -, scaled mean life span
  %tm = 1e4;

  [uE0 lb info] = get_ue0([g k vHb], f);
  if info == 0
    r = 0;
    fprintf('sgr_iso warning: ue0 could not be obtained\n');
    lp_out = 0; tp_out = 0; tb = 0;
    return
  end
  rho0 = kapR * (1 - kap)/ uE0;

  [tp tb lp lb info] = get_tp([g k lT vHb vHp], f, lb);
  if lp > f || info == 0 || tp < 0
    r = 0;
    info = 0;
    fprintf('sgr_iso warning: lp > f\n');
    tp_out = 0; lp_out = 0;
    return
  end

  % initialize range for r/k_M
  rho_0 = 1e-8; 
  norm_0 = fnsgr_iso(f, rho_0, rho0, rhoB, lT, lp, li, tp, g, k, vHp, hWG3, hW, hG, tm);
  rho_1 = reprod_rate(f * Lm, f, p, lb * Lm)/kM; % R_i/ k_M
  norm_1 = fnsgr_iso(f, rho_1, rho0, rhoB, lT, lp, li, tp, g, k, vHp, hWG3, hW, hG, tm);
  if norm_0 < 0 || norm_1 > 0
    %fprintf('sgr_iso warning: invalid parameter combination\n')
    %printpar({'lower boundary'; 'upper boundary'}, [rho_0; rho_1], [norm_0; norm_1], 'r, char eq'); 
    rho = fzero(@(rho) exp(-rho * tp) - exp(rho/ rho_1) + 1, 1e-8); % see (9.22) of DEB3
    r = rho * kM; % spec pop growth rate
    info = 2;
    lp_out = lp; tp_out = tp; 
    return
  end
  norm = 1; i = 0; % initialize norm and counter

  while i < 200 && norm^2 > 1e-20 % bisection method
    i = i + 1;
    rho = (rho_0 + rho_1)/ 2;
    norm = fnsgr_iso(f, rho, rho0, rhoB, lT, lp, li, tp, g, k, vHp, hWG3, hW, hG, tm);
    if norm > 0
        rho_0 = rho;
    else
        rho_1 = rho;
    end
  end

  r = rho * kM; % spec pop growth rate

  if i == 200
    info = 0;
    fprintf('sgr_iso warning: no convergence for r in 200 steps\n')
  else
    info = 1;
    %fprintf(['sgr_iso warning: successful convergence for r in ', num2str(i), ' steps\n'])
  end

  lp_out = lp; % copy lp to output
  tp_out = tp; % copy tp to output
  
end
