function varargout = mtm(input, NW, M, Fs, varargin)
    %mtm   Power spectral density estimate via the Thomson multitaper 
    %   method (MTM). In essence, this function
    %   fixes the number of fft points to N = number of sample points in
    %   the input, and uses fft function in MATLAB (instead of
    %   computeDFT or czt used in pmtm function) to calculate FFT
    %   This function accepts four inputs, input, NW, M, and Fs
    %
    %   For example, [S_mtm, F_mtm] = mtm(input,NW,M,Fs)
    %
    %   input = discrete-time signal X. When X is a vector, it is converted
    %   to a column vector and treated as a single channel.  When X is a
    %   matrix, the PSD is computed independently for each column and
    %   stored in the corresponding column of S_mtm
    %
    %   NW = "time-bandwidth product" for the discrete prolate spheroidal
    %   sequences (or Slepian sequences) used as data windows.  Typical
    %   choices for NW are 2, 5/2, 3, 7/2, or 4. 
    %
    %   M = number of tapers to use. If left empty, the default value of
    %   2*NW - 1 is used.
    %
    %   Fs = sampling frequency in hertz.
    %
    %   The algorithm for combining the individual spectral estimates can
    %   also be specified as the fourth input, as one of the following:
    %      'adapt'  - Thomson's adaptive non-linear combination (default).
    %      'unity'  - linear combination with unity weights.
    %      'eigen'  - linear combination with eigenvalue weights.
    %
    %   The fourier coefficients can also be obtained by specifying the
    %   third output, for example = [S_mtm, F_mtm, X_mtm] = mtm(...);
    %
    %   The weights used for combining the individual spectral estimates
    %   can also be obtained by specifying the fourth output, for example =
    %   [S_mtm, F_mtm, X_mtm, weights_mtm] = mtm(...); 

    % convert vectors to column vectors for backwards compatibility
    if isvector(input)
        input = input(:);
    end
    
    if isa(input, 'single')
       input = double(input);
    end
    
    N = size(input, 1);
    Nchan = size(input, 2);
    
    if isempty(M)
        M = 2*NW-1; % number of tapers to use
    end    
    
    F_mtm = (0:N-1)*Fs/N; % frequencies at which FFT is calculated
    
    if isempty(varargin)
        method = 'adapt';
        % generate tapers
        [E, V_orig] = dpss(N, NW);
        V = V_orig(1:M);        
    elseif numel(varargin) == 3 % both method and tapers specified
        method = varargin{1};
        
        if isempty(method)
            method = 'adapt';
        end
        
        % use user-specified tapers
        E = varargin{2};
        V_orig = varargin{3};
        
        if isempty(E) || isempty(V_orig)
            % generate tapers
            [E, V_orig] = dpss(N, NW);
        end
        V = V_orig(1:M);
    else % for any other number of varargin
        method = varargin{1};
        
        if isempty(method)
            method = 'adapt';
        end
        
        % generate tapers since only one or none of the necessary
        % information is provided
        [E, V_orig] = dpss(N, NW);
        V = V_orig(1:M);
    end

    % compute DFT for each tapered signal
    S_mtm = zeros(N, Nchan);
    X_mtm = zeros(N, M, Nchan);
    
    if strcmp(method, 'adapt')
        weights_mtm = zeros(N, M, Nchan);
    else
        weights_mtm = zeros(M, Nchan);
    end
    
    for chan = 1:Nchan
        X = zeros(N, M);
        x = input(:,chan);
        for m = 1:M
            X(:,m) = fft(bsxfun(@times, E(:,m), x));
        end

        % compute MT spectral estimate
        %S_hat = 1/Fs*abs(X).^2;
        S_hat = abs(X).^2;

        switch method

        case 'adapt'
            sig2=x'*x/N;              % Power
            Schan=(S_hat(:,1)+S_hat(:,2))/2;    % Initial spectrum estimate (mean of first two spectrum estimates)   
            S1=zeros(N,1);

            % The algorithm converges so fast that results are
            % usually 'indistinguishable' after about three iterations.

            % This version uses the equations from [2] (P&W pp 368-370).

            % Set tolerance for acceptance of spectral estimate:
            tol=.0005*sig2/N;
            a=bsxfun(@times,sig2,(1-V));

            % Do the iteration:
            while sum(abs(Schan-S1)/N)>tol
              % calculate weights
              b=(Schan*ones(1,M))./(Schan*V'+ones(N,1)*a'); 
              % calculate new spectral estimate
              wk=(b.^2).*(ones(N,1)*V');
              S1=sum(wk'.*S_hat')./ sum(wk,2)';
              S1=S1';
              Stemp=S1; S1=Schan; Schan=Stemp;  % swap S and S1
            end
            
            weights_mtm(:,:,chan) = wk;
        case {'unity','eigen'}
           % Compute the averaged estimate: simple arithmetic averaging is used. 
           % The Sk can also be weighted by the eigenvalues, as in Park et al. 
           % Eqn. 9.; note that the eqn. apparently has a typo; as the weights
           % should be V and not 1/V.
           if strcmp(method,'eigen')
              wt = V(:);    % Park estimate
           else
              wt = ones(M,1);
           end
           Schan = S_hat*wt/M;
           
           weights_mtm(:,chan) = wt;
        end

        S_mtm(:,chan) = Schan;
        X_mtm(:,:,chan) = X;
    end
    
    % Calculate the PSD (i.e., spectrum / Fs)
    S_mtm = S_mtm/Fs; 
    % note: this power spectral density will be half of that computed by
    % using MATLAB's pmtm function with 'one-sided' option, but same as the
    % computed by using pmtm function with 'two-sided' option
    
    if nargout==2
        varargout = {S_mtm,F_mtm};
    elseif nargout==3
        varargout = {S_mtm,F_mtm,X_mtm};
    elseif nargout==4
        varargout = {S_mtm,F_mtm,X_mtm,weights_mtm};        
    end
end