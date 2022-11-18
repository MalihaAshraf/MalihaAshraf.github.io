classdef CSF_castleCSF < CSF_base
    % Colour, Area, Spatial frequency, Temporal frequency, Luminance,
    % Eccentricity dependent Contrast Sensitivity Function (CSF)
    
    properties( Constant )
       % which entries in the meachism matrix should be fixed to 1
        Mones = [ 1 0 0;
            1 0 0;
            0 0 1 ];
        chrom_ch_beta = 2;
        
        Y_min = 0.001;  % The minimum luminance
        Y_max = 10000;  % The maximum luminance
        rho_min = 2^-4  % The minimum spatial frequency
        rho_max = 64;   % The maximum spatial frequency
        ecc_max = 120;  % The maximum eccentricity
    end
    
    properties  
        use_gpu = true;
        ps_beta = 1;
    end
    
    methods
       
        function obj = CSF_castleCSF ( )
            obj.par = obj.get_default_par();
        end
        
        function name = short_name( obj )
            % A short name that could be used as a part of a file name
            name = 'castle-csf';
        end

        function name = full_name( obj )
            name = 'castleCSF';
        end
        
         function M_lms2acc = get_lms2acc( obj )
            % Get the colour mechanism matrix
            
            M_lms2acc = ones(3,3);
            % Set only the cells in the array that should be ~= 1
            if isfield(obj.par, 'colmat')
                M_lms2acc(~CSF_ConeContrastMat.Mones(:)) = obj.par.colmat;
            else
                colmat = [ 0.00123883 0.229778 0.932581 1.07013 6.41585e-07 0.0037047 ];
                M_lms2acc(~CSF_ConeContrastMat.Mones(:)) = colmat;
            end 
            % Get the right sign
            M_lms2acc =  M_lms2acc .* [ 1 1 1; 1 -1 1; -1 -1 1];
         end
        
        function S = sensitivity( obj, csf_pars )
            
            csf_pars = obj.test_complete_params(csf_pars, { 'lms_bkg', 'ge_sigma' }, true );

            ecc = csf_pars.eccentricity;
            sigma = csf_pars.ge_sigma;
            rho = csf_pars.s_frequency;
            omega = csf_pars.t_frequency;
            lms_bkg = csf_pars.lms_bkg;
            lms_delta = csf_pars.lms_delta;
%             if exist('csf_pars.luminance', 'var')
%                 lum = csf_pars.luminance;
%             else
%                 lum = sum(lms_bkg,ndims(lms_bkg));
%             end
%             
            
            A = pi*(sigma).^2; % Stimulus area
                        
            [R_sust, R_trans] = get_sust_trans_resp(obj, omega);
%             [R_rg_sust, R_rg_trans] = get_sust_trans_resp(obj, omega, 2);
%             [R_yv_sust, R_yv_trans] = get_sust_trans_resp(obj, omega, 3);
            
            [S_achrom_sust, S_rg_sust, S_yv_sust] = obj.csf_sust_trans( rho, A, lms_bkg, lms_delta, ecc, obj.par.sust );                
            [S_achrom_trans, S_rg_trans, S_yv_trans] = obj.csf_sust_trans( rho, A, lms_bkg, lms_delta, ecc, obj.par.trans );

                C_sust = ( ((1./(S_achrom_sust)).^obj.chrom_ch_beta... 
                    + ( 1./(S_rg_sust) ).^obj.chrom_ch_beta ...
                    + ( 1./(S_yv_sust) ).^obj.chrom_ch_beta).^(1/obj.chrom_ch_beta) );
                C_trans = ( ((1./(S_achrom_trans)).^obj.chrom_ch_beta... 
                    + ( 1./(S_rg_trans) ).^obj.chrom_ch_beta ...
                    + ( 1./(S_yv_trans) ).^obj.chrom_ch_beta).^(1/obj.chrom_ch_beta) );
                
                mat_size = [ones(1, numel(size(lms_delta))-1), 3];
                
                LMS_delta_thr_sust = repmat((C_sust.^(-1)), mat_size) .* lms_delta;
                S_sust = 1./ (sqrt(sum((LMS_delta_thr_sust ./ lms_bkg).^2, numel(mat_size)))/sqrt(3));       
                
                LMS_delta_thr_trans = repmat((C_trans.^(-1)), mat_size) .* lms_delta;
                S_trans = 1./ (sqrt(sum((LMS_delta_thr_trans ./ lms_bkg).^2, numel(mat_size)))/sqrt(3));       
                
                if numel(size(lms_delta)) > 2
                    dim3_size = size(lms_delta);
                    dim1_size = dim3_size(1:end-1);
                else
                    dim1_size = [size(lms_delta, 1), 1];
                end
                
                lms_delta_rs = reshape(lms_delta, numel(lms_delta)/3, 3);
                sign = [(lms_delta_rs >= 0), (lms_delta_rs(:,1)+lms_delta_rs(:,2) > lms_delta_rs(:,3))];
                achrom_sign = reshape(sign(:,1) & sign(:,2) & sign(:,3) & sign(:,4), dim1_size);
                
                if isfield(obj.par, 'chrom_sust_ratio')
                    chrom_sust_ratio = obj.par.chrom_sust_ratio;
                else
                    chrom_sust_ratio = 4.11264;
                end
                
                if isfield(obj.par, 'chrom_trans_ratio')
                    chrom_trans_ratio = obj.par.chrom_trans_ratio;
                else                
                    chrom_trans_ratio = 0.477235;
                end

                
                if (numel(R_trans) ~= numel(achrom_sign)) || (numel(R_sust) ~= numel(achrom_sign))
                    R_sust = repmat(R_sust, size(achrom_sign));
                    R_trans = repmat(R_trans, size(achrom_sign));
                    
                    R_sust(~achrom_sign) = R_sust(~achrom_sign).*chrom_sust_ratio;                
                    R_trans(~achrom_sign) = R_trans(~achrom_sign).*chrom_trans_ratio;                
                else
                    R_sust(~achrom_sign) = R_sust(~achrom_sign).*chrom_sust_ratio;                 
                    R_trans(~achrom_sign) = R_trans(~achrom_sign).*chrom_trans_ratio;                 
                end
                              
                S_aux = 0; %obj.aux_sensitivity( csf_pars );
                pm_ratio=1;
                if obj.ps_beta ~= 1 
                    beta = obj.ps_beta;
                    S = ( (R_sust.*S_sust .* sqrt(pm_ratio)).^beta + (R_trans.*S_trans .* sqrt(1./pm_ratio)).^beta + S_aux.^beta).^(1/beta);
                else
                    S = R_sust.*S_sust .* sqrt(pm_ratio) + R_trans.*S_trans .* sqrt(1./pm_ratio) + S_aux;
                end
            
            % The drop of sensitivity with the eccentricity (the window of
            % visibiliy model + extension)
            
            % to-do
            S_ecc = S;
        end
        
        function S = sensitivity_edge(obj, csf_pars)
            
            t_freqs = csf_pars.t_frequency;
            tf_sel = t_freqs == 0;   % Check whether disk is static or temporally modulated
            
            csf_pars_orig = csf_pars;
            
            if isempty(tf_sel)
                S = [];
                return;
            end
            
            %%%%%%%%%%% for tf = 0
            if numel(find(~tf_sel)) > 0
                csf_pars.s_frequency = logspace( log10(0.125), log10(16), 100 )';
%                 csf_pars.t_frequency = t_freqs(~tf_sel);
                csf_pars = obj.test_complete_params(csf_pars, { 'luminance', 'ge_sigma' } );
                radius = csf_pars.ge_sigma; % Store ge_sigma for multiple receptor circumference model
                radius = radius(:);
                csf_pars = rmfield(csf_pars, 'ge_sigma');
                csf_pars.area = 3.09781; % Replace area parameter with fixed optimized area

                beta =4;
                S_gabor = sensitivity(obj, csf_pars);
                S1 = S_gabor.* (radius'.^(1/beta));
                S1 = max(S1);

                S1 = permute(S1, circshift(1:numel(size(S1)), -1)); 
                S(~tf_sel) = S1(~tf_sel);
                
                if numel(find(~tf_sel)) == numel(t_freqs)
                    S = S1;
                    return
                else
                    1;
                end
            end

            %%%%%%%%% for tf ~= 0
            if numel(find(tf_sel)) > 0
                csf_pars = csf_pars_orig;
%                 csf_pars.t_frequency = t_freqs(tf_sel);
                csf_pars = obj.test_complete_params(csf_pars, { 'luminance', 'ge_sigma' } );
                radius = csf_pars.ge_sigma; % Store ge_sigma for multiple receptor circumference model
                csf_pars.s_frequency = 0.5./(2*radius);
                S_gabor = (4/pi).*sensitivity(obj, csf_pars);
%                 if 0%numel(csf_pars.s_frequency) ~= 1
%                     S2 = diag(S_gabor);
%                 else
%                     
%                 end
                
                S2 = S_gabor';
                if numel(find(tf_sel)) == numel(t_freqs)
                    S = S2;
                    return
                end
            end
            
%             if (numel(tf_sel) == 1) && (tf_sel == 0)
%                 S = S2;
%             elseif (numel(tf_sel) == 1) && (tf_sel == 1)
%                 S = S1;
%             else
%                 S = S2;
%                 S(tf_sel) = S1(tf_sel);
%             end
            

                S = S1;
                S(~tf_sel) = S1(~tf_sel);
                S(tf_sel) = S2(tf_sel);

        end
        
        
        function [R_sust, R_trans] = get_sust_trans_resp(obj, omega)
            if isfield( obj.par, 'sigma_sust' )
                sigma_sust = obj.par.sigma_sust;
            else
                sigma_sust = 8.30368;
            end
            
            if isfield(obj.par, 'sigma_trans')
                sigma_trans = obj.par.sigma_trans;
            else
                sigma_trans = 0.00344898;
            end
            
            if isfield( obj.par, 'beta_sust' )
                beta_sust = obj.par.beta_sust;
            else
                beta_sust = 1.70163;
            end

            if isfield( obj.par, 'beta_trans' )
                beta_trans = obj.par.beta_trans;
            else
                beta_trans = 0.0477296;
            end
            
            omega_0 = 5;
            
            R_sust = exp( -omega.^beta_sust / (sigma_sust) );
            R_trans = exp( -abs(omega.^beta_trans-omega_0^beta_trans).^2 / (sigma_trans) );
        end
        
        function [S_A_n, S_R_n, S_Y_n] = csf_sust_trans( obj, freq, area, LMS_mean, LMS_delta, ecc, pars )
           
            M_lms2acc = obj.get_lms2acc();
            
            lum = sum(LMS_mean,ndims(LMS_mean));
            
%             if (size(freq, 1) ~= size(LMS_mean, 1)) && (numel(freq)~=1) && (numel(LMS_mean)~=3)
            if (numel(size(LMS_mean)) > 2)  && (numel(LMS_mean)~=3)
                dim3_size = size(LMS_mean);
                dim1_size = dim3_size(1:end-1);
            else
                dim1_size = [size(LMS_mean, 1), 1];
            end
            
            CC_LMS = LMS_delta ./ LMS_mean;
            
            CC_ACC = reshape(CC_LMS, numel(CC_LMS)/3, 3) * M_lms2acc';
                        
            C_A = reshape(abs(CC_ACC(:,1)), dim1_size);
            C_R = reshape(abs(CC_ACC(:,2)), dim1_size);
            C_Y = reshape(abs(CC_ACC(:,3)), dim1_size);
            
            S_A_n = 1./(C_A.*obj.csf_freq_size_lum( freq, area, 1, lum, pars(1) ));
            S_R_n = 1./(C_R.*obj.csf_freq_size_lum( freq, area, 2, lum, pars(2) ));
            S_Y_n = 1./(C_Y.*obj.csf_freq_size_lum( freq, area, 3, lum, pars(3) ));
            
        end
        
        function S = csf_freq_size_lum( obj, freq, area, color_dir, lum, pars )
            % Internal. Do not call from outside the object.
            % A nested CSF as a function of luminance
            
            
            % Support for a GPU
            if isa( freq, 'gpuArray' ) || isa( area, 'gpuArray' ) || isa( color_dir, 'gpuArray' ) || isa( lum, 'gpuArray' )
                cl = 'gpuArray';
            else
                cl = class(freq);
            end
            
            Nl = length(lum);
            S_max = zeros(Nl,1, cl);
            f_max = zeros(Nl,1, cl);
            bw = pars.bw;
%             a = sust_pars.a;

            
            S_max = obj.get_lum_dep( pars.S_max, lum );
            f_max = obj.get_lum_dep( pars.f_max, lum );
            
            % Truncated log-parabola  for chromatic channels
            S_LP = 10.^( -(log10(freq) - log10(f_max)).^2./(2.^bw) );
            if color_dir == 1
%                 ss = (freq<f_max) & (S_LP < (1-a));
%                 S_LP(ss) = 1-a;
            else
                ss = (freq<f_max) ;
                max_mat = repmat(max(S_LP), size(freq));
                if numel(max_mat) == 1
                    S_LP(ss) = max_mat;
                else
                    S_LP(ss) = max_mat(ss);
                end
                
            end
            
            S_peak = S_max .* S_LP;
            
             % The stimulus size model from the paper:
            %
            % Rovamo, J., Luntinen, O., & N�s�nen, R. (1993).
            % Modelling the dependence of contrast sensitivity on grating area and spatial frequency.
            % Vision Research, 33(18), 2773�2788.
            %
            % Equation on the page 2784, one after (25)
            
            
            if isfield( pars, 'f0' )
                f0 = pars.f0;
            else
                f0 = 0.65;
            end
            if isfield( pars, 'A0' )
                A0 = pars.A0;
            else
                A0 = 270;
            end

            Ac = A0./(1+(freq/f0).^2);

            S = S_peak .* sqrt( Ac ./ (1+Ac./area)).*(freq.^1);
            
        end
        
        function pd = get_plot_description( obj )
            pd = struct();
            pp = 1;
            pd(pp).title = 'Sustained and transient response';
            pd(pp).id = 'sust_trans';
            pp = pp+1;
            
        end
        
        function plot_mechanism( obj, plt_id )
            switch( plt_id )
                case 'sust_trans' % sust-trans-response
                    clf;
                    html_change_figure_print_size( gcf, 10, 10 );
                    omega = linspace( 0, 100 );
                    [R_sust, R_trans] = obj.get_sust_trans_resp(omega);
                    hh(1) = plot( omega, R_sust, 'DisplayName', 'Sustained (achromatic)');
                    hold on
                    hh(2) = plot( omega, R_sust.*obj.par.chrom_sust_ratio, 'DisplayName', 'Sustained (chromatic)');
                    hh(3) = plot( omega, R_trans, 'DisplayName', 'Transient (achromatic)');
                    hh(4) = plot( omega, R_trans.*obj.par.chrom_trans_ratio, 'DisplayName', 'Transient (chromatic)');
                    hold off
                    xlabel( 'Temp. freq. [Hz]' );
                    ylabel( 'Response' );
                    legend( hh, 'Location', 'Best' );
                    grid on;
                otherwise
                    error( 'Wrong plt_id' );
                    
            end
        end
        
        function print( obj, fh )
            % Print the model parameters in a format ready to be pasted into
            % get_default_par()
            
            for cc=1:3
                fn = fieldnames( obj.par.sust(cc) );
                for ff=1:length(fn)
                    fprintf( fh, '\tp.sust(%d).%s = ', cc, fn{ff} );
                    obj.print_vector( fh, obj.par.sust(cc).(fn{ff}) );
                    fprintf( fh, ';\n' );
                end
                fprintf( 1, '\n' )
            end
            
            for cc=1:3
                fn = fieldnames( obj.par.trans(cc) );
                for ff=1:length(fn)
                    fprintf( fh, '\tp.trans(%d).%s = ', cc, fn{ff} );
                    obj.print_vector( fh, obj.par.trans(cc).(fn{ff}) );
                    fprintf( fh, ';\n' );
                end
                fprintf( 1, '\n' )
            end
            
            fn = fieldnames( obj.par );
            for ff=1:length(fn)
                if ismember( fn{ff}, { 'sust', 'trans', 'ds' } )
                    continue;
                end
                fprintf( fh, '\tp.%s = ', fn{ff} );
                obj.print_vector( fh, obj.par.(fn{ff}) );
                fprintf( fh, ';\n' );
            end
            
            M_lms2acc = obj.get_lms2acc();
            
            fprintf( fh, evalc( 'M_lms2acc' ) );
            
        end
    end
    
    methods ( Static )
       
        function p = get_default_par()

            p = CSF_base.get_dataset_par();
            
%     p.sust(1).S_max = [ 1245.23 60646.1 0.157273 841.487 3.07523 ];
% 	p.sust(1).f_max = [ 1.48196 709489 0.0102663 ];
% 	p.sust(1).bw = 1.80018e-07;
% 	p.sust(1).A0 = 59388.4;
% 	p.sust(1).f0 = 0.0535977;
% 
% 	p.sust(2).S_max = [ 2728.23 8.5007 1.04459 ];
% 	p.sust(2).f_max = 0.699529;
% 	p.sust(2).bw = 2.04656e-111;
% 	p.sust(2).A0 = 1.24795;
% 	p.sust(2).f0 = 0.0223687;
% 
% 	p.sust(3).S_max = [ 3040.37 1.40933e-33 5.61779 ];
% 	p.sust(3).f_max = 74410.2;
% 	p.sust(3).bw = 0.0686534;
% 	p.sust(3).A0 = 2.8626e+32;
% 	p.sust(3).f0 = 0.0546761;
% 
% 	p.trans(1).S_max = [ 1.00051e-223 58.4685 ];
% 	p.trans(1).f_max = 8.14135e+12;
% 	p.trans(1).bw = 1.12748;
% 	p.trans(1).A0 = 0.0101094;
% 	p.trans(1).f0 = 7.74382e+15;
% 
% 	p.trans(2).S_max = [ 0.0339747 2.91671e+08 ];
% 	p.trans(2).f_max = 1.45288e+07;
% 	p.trans(2).bw = 4.43882e-29;
% 	p.trans(2).A0 = 1.66955e-05;
% 	p.trans(2).f0 = 0.000242527;
% 
% 	p.trans(3).S_max = [ 0.19038 346.86 ];
% 	p.trans(3).f_max = 0.156318;
% 	p.trans(3).bw = 0.144344;
% 	p.trans(3).A0 = 3.58671e+22;
% 	p.trans(3).f0 = 0.00116672;
% 
% 	p.sigma_sust = 14.5272;
% 	p.sigma_trans = 3.84589e-15;
% 	p.achrom_trans_ratio = 0.365674;
% 	p.achrom_sust_ratio = 11.3603;
% 	p.beta_sust = 1.19719;
% 	p.beta_trans = 6.40075e-08;
% 	p.colmat = [ 7.85997e-78 0.364789 0.098694 2.97445e-72 4.31729e-151 5.56279e-154 ];


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%    
    
%     p.sust(1).S_max = [ 6.16422 2.21981e+07 0.331466 41.0115 13.5653 ];
% 	p.sust(1).f_max = [ 0.0335088 0.000208167 2501.95 ];
% 	p.sust(1).bw = 797777;
% 	p.sust(1).A0 = 1.80804;
% 	p.sust(1).f0 = 0.00080749;
% 
% 	p.sust(2).S_max = [ 952910 1.29712e-175 1.77801 ];
% 	p.sust(2).f_max = 0.000522819;
% 	p.sust(2).bw = 0.118815;
% 	p.sust(2).A0 = 9.50454e+133;
% 	p.sust(2).f0 = 6.67409e-35;
% 
% 	p.sust(3).S_max = [ 4.17454 1.66951e+267 4.33077e-27 ];
% 	p.sust(3).f_max = 2.10439;
% 	p.sust(3).bw = 3.23263e-78;
% 	p.sust(3).A0 = 5.01911e+22;
% 	p.sust(3).f0 = 7.39153e-11;
% 
% 	p.trans(1).S_max = [ 0.74107 40.9772 ];
% 	p.trans(1).f_max = 9.26563e-05;
% 	p.trans(1).bw = 0.0857712;
% 	p.trans(1).A0 = 558.91;
% 	p.trans(1).f0 = 0.0213786;
% 
% 	p.trans(2).S_max = [ 0.136108 9.8478 ];
% 	p.trans(2).f_max = 1.13629;
% 	p.trans(2).bw = 9.83973e-67;
% 	p.trans(2).A0 = 373.217;
% 	p.trans(2).f0 = 0.128897;
% 
% 	p.trans(3).S_max = [ 0.684149 0.0440057 ];
% 	p.trans(3).f_max = 0.107156;
% 	p.trans(3).bw = 1.7276e-23;
% 	p.trans(3).A0 = 2.14336e+44;
% 	p.trans(3).f0 = 1.06728e-05;
% 
% 	p.sigma_sust = 4.0137;
% 	p.sigma_trans = 1.41907;
% 	p.achrom_trans_ratio = 1.02382;
% 	p.achrom_sust_ratio = 3.06934;
% 	p.beta_sust = 1.05252;
% 	p.beta_trans = 0.388319;
% 	p.colmat = [ 11.351 267866 1.00793e-51 1.34174e-34 2.40008e-16 4.30022 ];

%     0.0452 error for campbell and swanson
%     p.sust(1).S_max = [ 6.89821 2.92245e+07 0.350645 22.3674 30.3794 ];
% 	p.sust(1).f_max = [ 0.0335088 0.000208167 2501.95 ];
% 	p.sust(1).bw = 797777;
% 	p.sust(1).A0 = 2.26425;
% 	p.sust(1).f0 = 0.00080749;
% 
% 	p.sust(2).S_max = [ 1.00177e+06 1.29712e-175 1.77801 ];
% 	p.sust(2).f_max = 0.000522819;
% 	p.sust(2).bw = 0.142425;
% 	p.sust(2).A0 = 9.50454e+133;
% 	p.sust(2).f0 = 6.92912e-35;
% 
% 	p.sust(3).S_max = [ 5.56504 1.66951e+267 4.33077e-27 ];
% 	p.sust(3).f_max = 2.25416;
% 	p.sust(3).bw = 3.23263e-78;
% 	p.sust(3).A0 = 4.40175e+22;
% 	p.sust(3).f0 = 6.60505e-11;
% 
% 	p.trans(1).S_max = [ 0.74107 40.9772 ];
% 	p.trans(1).f_max = 9.26563e-05;
% 	p.trans(1).bw = 0.0857712;
% 	p.trans(1).A0 = 538.339;
% 	p.trans(1).f0 = 0.0327005;
% 
% 	p.trans(2).S_max = [ 0.0995787 13.8876 ];
% 	p.trans(2).f_max = 1.56286;
% 	p.trans(2).bw = 9.83973e-67;
% 	p.trans(2).A0 = 553.305;
% 	p.trans(2).f0 = 0.0656287;
% 
% 	p.trans(3).S_max = [ 0.335518 0.634647 ];
% 	p.trans(3).f_max = 0.105825;
% 	p.trans(3).bw = 1.7276e-23;
% 	p.trans(3).A0 = 4.05469e+44;
% 	p.trans(3).f0 = 1.51454e-05;
% 
% 	p.sigma_sust = 15.7756;
% 	p.sigma_trans = 0.754841;
% 	p.achrom_trans_ratio = 1.1315;
% 	p.achrom_sust_ratio = 6.45731;
% 	p.beta_sust = 2.32783;
% 	p.beta_trans = 0.341621;
% 	p.colmat = [ 13.7778 271235 1.00793e-51 1.34174e-34 2.40008e-16 4.16792 ];
    


    p.sust(1).S_max = [ 3.06733 0.00124452 416.242 0.413922 1214.52 ];
	p.sust(1).f_max = [ 1.26298e+19 6.1704e+3 2.08282e-31 ];
	p.sust(1).bw = 167.769;
	p.sust(1).A0 = 0.0430468;
	p.sust(1).f0 = 0.000194357;

	p.sust(2).S_max = [ 12176.1 1.01205e-17 0.144242 ];
	p.sust(2).f_max = 1984.01;
	p.sust(2).bw = 0.308238;
	p.sust(2).A0 = 5.54976e+11;
	p.sust(2).f0 = 1.59837e-6;

	p.sust(3).S_max = [ 0.0735951 306.349 3.39254e+07 ];
	p.sust(3).f_max = 14.8938;
	p.sust(3).bw = 7.70079e+13;
	p.sust(3).A0 = 2.38642e+2;
	p.sust(3).f0 = 1.18326e-11;

	p.trans(1).S_max = [ 0.251998 348078 ];
	p.trans(1).f_max = 1.33658e-05;
	p.trans(1).bw = 0.0999939;
	p.trans(1).A0 = 3.01183e+15;
	p.trans(1).f0 = 2.27321e-09;

	p.trans(2).S_max = [ 0.29236 0.062399 ];
	p.trans(2).f_max = 0.213548;
	p.trans(2).bw = 1.06376;
	p.trans(2).A0 = 166589;
	p.trans(2).f0 = 0.0195589;

	p.trans(3).S_max = [ 7.34462e-24 9.75042e-14 ];
	p.trans(3).f_max = 1.13403e-07;
	p.trans(3).bw = 1.71879e+07;
	p.trans(3).A0 = 1.06087e+12;
	p.trans(3).f0 = 1.04928e-14;

	p.sigma_sust = 2.41196;
	p.sigma_trans = 20.611;
	p.chrom_sust_ratio = 0.412742;
	p.chrom_trans_ratio = 1.29293;
	p.beta_sust = 150.41;
	p.beta_trans = 0.625883;
	p.colmat = [ 3.96378e-3 78812.9 622.683 2.06106e+06 2.04419e-5 119.333 ];



  
    
        end
    end
end
