grep -v "^#" WGS_4_5_6.small.vcf | awk '{
    ref = $4; alt = $5;
    
    # Define Transitions (A<->G, C<->T)
    if ((ref=="A" && alt=="G") || (ref=="G" && alt=="A") || 
        (ref=="C" && alt=="T") || (ref=="T" && alt=="C")) {
        ti++
    } 
    # Everything else is a Transversion (assuming biallelic SNPs)
    else {
        tv++
    }
} 
END {
    print "Transitions: " ti
    print "Transversions: " tv
    print "Ti/Tv Ratio: " ti/tv
}'
