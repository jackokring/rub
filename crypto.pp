unit crypto
        (* this unit implements cryptography using 2 simple-ish systems known as RSA and ElGamal (cyclic group)  *)

interface
        (* all strings are base64 encoded. larger strings must be split before crypto is used. *)
        const
                upper = 255;
        type
                (* i seem to have this as little endian cardinal ordering *)
                value = array [0 .. upper] of cardinal;
                pair = array [0 .. 1] of value;
                key = record
                        (* public *)
                        kModulus: value;

                        (* private *)

                end;

        (* key and general encryption fiunctions *)
        function encrypt(value, key): value; (* public *)
        function decrypt(value, key): value; (* private *)
        function loadPubKey(string): key;
        function savePubKey(key0: string;
        function loadPrivKey(string): key;
        function savePrivKey(key): string;
        function mergePubPriv(key, key): key;
        function createKey(): key;

        (* value loading functions *)
        function load(string): value;
        function save(string): value;
        function splitLoad(string): array of value; (* must set modulus before this *)
        function splitSave(array of value): string;
        function splitEncrypt(array of value, key): array of value;
        function splitDecrypt(array of value, key): array of value;

        (* arithmetic functions *)
        function add(value, value): value;
        function mul(value, value): value;
        function setModulus(value): value; (* old *)
        function negate(value): value; (* not a modulo negate, but for subtraction *)
        function sub(value, value): value;

        (* more advanced functions *)
        function divide(value, value): pair; (* 0 = quotient, 1 = remainder *)
        function power(value, value): value;
        function gcd(value, value): value;
        function inverse(value): value;
        function greater(value, value): boolean; (* or equal to *)

implementation
        uses base64;

        var
                iModulus: value; (* two's complement modulus *)
                modulus: value;
                zero: value;
                one: value;
                nogo: boolean;

        function addc(a: cardinal, b: cardinal, c: cardinal): cardinal;
        var
                tmp: QWord;
        begin
                tmp := a + b + c;
                addc := tmp >> 32;
        end;

        function addt(a: value, b: value, d: boolean): value;
        var
                i: integer;
                c: cardinal = 0;
        begin
                for i = 0 to upper do
                begin
                        addt[i] := a[i] + b[i] + c;
                        c := addc(a[i], b[i], c);
                end;
                if d and c <> 0 then addt := addt(addt, iModulus, false); (* horrid nest fix *)
        end;

        function greater(a: value, b: value): boolean;
        var
                i: integer;
        begin
                for i = upper downto 0 do
                begin
                        if a[i] < b[i] then
                        begin
                                greater := false;
                                exit;
                        end;
                        if a[i] > b[i] then
                        begin
                                greater := true;
                                exit;
                        end;
                end;
                greater := true; (* should make 0 *)
        end;

        procedure round(var a: value);
        begin
                if greater(modulus, one) then (* zero is no modulus *)
                        while greater(a, modulus) do
                                a := addt(a, iModulus, false);
        end;

        function add(a: value, b: value, d: boolean): value;
        begin
                add := addt(a, b, true);
                round(add);
        end;

        function negate(a: value): value;
        var
                i: integer;
        begin
                for i = 0 to upper do
                        a[i] := not a[i];
                addt(a, one, false);
        end;

        function setModulus(a: value): value;
        var
                i: integer;
        begin
                setModulus := modulus; (* save it *)
                for i = 0 to upper do
                        zero[i] := 0;
                one := zero;
                one[0] := 1;
                modulus := a;
                iModulus := negate(a);
        end;

        function sub(a: value, b: value): value;
        begin
                sub := addt(a, negate(b), false);
                nogo := false;
                if greater(b, a) then
                begin
                        (* remap the negative *)
                        sub := addt(sub, modulus, false);
                        nogo := true;
                end;
        end;

        function mul(a: value, b: value): value;
        var
                i: integer;
                f: boolean;
        begin
                mul := zero;
                for i = 0 to (upper+1)*32-1 do
                begin
                        if (a[i div 32] and (1 << (i mod 32))) <> 0 then f := true; else f := false;
                        if f then mul := add(mul, b);
                        b := add(b, b); (* effective shift under modulo field *)
                end;
        end;

        function power(a: value, b: value): value;
        var
                i: integer;
                f: boolean;
        begin
                power := one;
                for i = 0 to (upper+1)*32-1 do
                begin
                        if (a[i div 32] and (1 << (i mod 32))) <> 0 then f := true; else f := false;
                        if f then power := mul(power, b);
                        b := mul(b, b); (* effective square under modulo field *)
                end;
        end;

        function divide(a; value, b: value): pair;
        var
                i: integer;
                f: boolean;
                q, r, tmp: value;
        begin
                r := zero;
                q := zero;
                tmp := setModulus(zero);
                for i = 0 to (upper+1)*32-1 do
                begin
                        r := add(r, r);
                        if (a[upper] and (1 << 31)) <> 0 then
                                r := add(r, one);
                        a := add(a, a); (* shift *)
                        q := add(q, q); (* also *)
                        r := sub(r, b);
                        if nogo then
                                r := add(r, b); (* add back *)
                        else
                                q := add(q, one); (* divides *)
                end;
                pair[0] := q;
                pair[1] := r;
                temp := setModulus(tmp);
        end;

        function gcdt(a: value, b: value, c: boolean): value;
        var
                t, newt, q, temp: value;
                p: pair;
                s: boolean = true; (* positive *)
                news: boolean = true;
        begin
                t := zero;
                newt := one;
                temp := setModulus(zero);
                if greater(b, a) then
                begin
                        gcdt := a;
                        a := b;
                        b := gcdt; (* swap *)
                end;
                while b <> zero do
                begin
                        p := divide(a, b);
                        q := p[0];
                        gcdt := p[1];
                        a := b;
                        b := gcdt;
                        if c then
                        begin
                                gcdt := newt;
                                if not s then
                                begin
                                        t := negate(t);
                                end;
                                if news then
                                begin
                                        newt := sub(t, mul(q, newt));
                                        if nogo then news := false; else news := true;
                                end;
                                if not news then
                                begin
                                        newt := add(t, mul(q, negate(newt)));
                                        news := true;
                                end;
                                if not s then
                                begin
                                        (* subtract 2t *)
                                        newt := sub(newt, t);
                                        if nogo then news := false;
                                        newt := sub(newt, t);
                                        if nogo then news := false;
                                end;
                                s := news;
                                t := gcdt;
                        end;
                end;
                if not c then gcdt := a;
                (* inv or not *)
                if c then gcdt := t;
                if not s then gcdt := add(gcdt, temp);
                if (greater(sub(a, one), one) and c) then gcdt := zero; (* no inverse *)
                temp := setModulus(temp);
        end;

        function gcd(a: value, b: value): value;
        begin
                gcdt(a, b, false);
        end;

        function inverse(a: value): value;
        begin
                gcdt(a, modulus, true);
        end;
end.