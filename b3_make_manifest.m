function b3_make_manifest()
%B3_MAKE_MANIFEST Freeze the B3 run registry (author's point 8).
%
% The approved pilot runs become formally the reported experiment
% WITHOUT renaming or overwriting any file: this manifest records which
% pilot file is which reported run, with MD5 hashes and the frozen
% configuration read from each State.parameters.
%
% Author: J. F. A. Madeira (2026). Phase B harness.

    entries = { ...
        'pilot_fixed_run1.mat', 'Fixed run reported in the paper (B3 ablation)'; ...
        'pilot_fixed_run2.mat', 'CC-DNR run reported in the paper (B3 ablation)'; ...
        'pilot_fixed_run3.mat', 'Full run reported in the paper (B3 ablation)'; ...
        'b3b_results.mat',      'B3b indexing-sensitivity experiment (res_fixed, res_ccdnr)'; ...
        'morap_nm_exact_front.csv', 'Frozen exact front (578 decisions; MATLAB<->Python cross-validated)'; ...
        'b3_anytime_curves.csv', 'Anytime post-processing curves (common-budget checkpoint)' };

    fid = fopen('B3_final_manifest.txt', 'w');
    fprintf(fid, 'B3 (MORAP-NM) final run manifest — %s\n', ...
            datestr(now, 'yyyy-mm-dd HH:MM:SS'));
    fprintf(fid, '==================================================\n\n');
    for k = 1:size(entries, 1)
        fname = entries{k, 1};
        fprintf(fid, 'file : %s\n', fname);
        fprintf(fid, 'role : %s\n', entries{k, 2});
        if exist(fname, 'file')
            fprintf(fid, 'md5  : %s\n', md5file(fname));
            if endsWith(fname, '.mat')
                S = load(fname);
                if isfield(S, 'State') && isfield(S.State, 'parameters')
                    P  = S.State.parameters;
                    fn = fieldnames(P);
                    fprintf(fid, 'cfg  :');
                    for j = 1:numel(fn)
                        val = P.(fn{j});
                        if ischar(val) || isstring(val)
                            fprintf(fid, ' %s=%s', fn{j}, char(val));
                        else
                            fprintf(fid, ' %s=%.10g', fn{j}, double(val));
                        end
                    end
                    fprintf(fid, '\n');
                    fprintf(fid, 'out  : func_eval=%d iter=%d iter_suc=%d list=%d\n', ...
                            S.State.func_eval, S.State.iter, ...
                            S.State.iter_suc, size(S.State.Flist, 2));
                end
            end
        else
            fprintf(fid, 'md5  : FILE NOT FOUND\n');
        end
        fprintf(fid, '\n');
    end
    fclose(fid);
    fprintf('B3_final_manifest.txt written.\n');
end


function h = md5file(fname)
    md  = java.security.MessageDigest.getInstance('MD5');
    fid = fopen(fname, 'r');
    bytes = fread(fid, inf, '*uint8');
    fclose(fid);
    md.update(bytes);
    h = lower(reshape(dec2hex(typecast(md.digest, 'uint8'))', 1, []));
end
