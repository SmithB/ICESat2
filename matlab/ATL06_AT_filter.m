function good=ATL06_AT_filter(D6, threshold)

[delta1, delta2]=deal(NaN(size(D6.h_li)));

hL=D6.h_li - 20*D6.dh_fit_dx;
hR=D6.h_li + 20*D6.dh_fit_dx;

delta1(1:end-1,:)= hR(1:end-1,:)-D6.h_li(2:end,:);
delta2(2:end-1)=hL(2:end,:)-D6.h_li(1:end-1,:);

good=max(abs(delta1), abs(delta2)) < threshold & isfinite(delta1+delta2);
good(2:end,:)=good(2:end,:) & good(1:end-1,:);