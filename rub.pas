program rub;
        (* this is the rub command line utility *)

        (*     rub infile [-b] [-h] [-z] [-m] [-s] [-e <.rub>] [-v] [-r] [-a] [-d] [-c] [-m] [-z] [-h] outfile     *)

        (* the command line options follow a pipe structure. from infile to outfile without the repeats
        they are as follows and (i) indicates REMOVAL of a feature from the pipe by the option:
                -b (i) backwards file read
                -h (i) hex encode/decode
                -z (i) compress/deompress using fast entropic method
                -m (i) 4096 bit encrypt/decrypt of stream (encyption of the rubikon still happens even if stream encryption is disabled by -m)
                -s digital signature
                -e encrypt using public keyfile (all public key facilitation needs this option)
                -v digital post signature for vouching of content
                -r (i) the rubikon (do not perform rubikon compression)
                -a pre decrypt voucher authentication
                -d decrypt using your private keyfile (all private key options need this)
                -c check digital signature
        and no other command options are supported. invalid command options displays help, and informs standard error. *)

        uses rubutil;
begin

end.
