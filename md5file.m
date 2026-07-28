function h = md5file(fname)
    fid  = fopen(fname, 'rb');
    data = fread(fid, Inf, '*uint8');
    fclose(fid);
    md   = java.security.MessageDigest.getInstance('MD5');
    md.update(data);
    h    = sprintf('%02x', typecast(md.digest(), 'uint8'));
end