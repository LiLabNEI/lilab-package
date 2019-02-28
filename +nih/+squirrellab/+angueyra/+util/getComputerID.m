function sid = getComputerID()
%uses ethernet address of computer netowrk card as unique identifier
sid = '';
ni = java.net.NetworkInterface.getNetworkInterfaces;
while ni.hasMoreElements
    addr = ni.nextElement.getHardwareAddress;
    if ~isempty(addr)
        addrStr = dec2hex(int16(addr)+128);
        sid = [sid, '.', reshape(addrStr,1,2*length(addr))]; %#ok<AGROW>
    end
end

end