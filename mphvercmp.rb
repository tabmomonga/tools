#!/usr/bin/env /usr/bin/ruby
#
#  version compare module
#
#  m_vercmp( sFirst, sSecond )
#  m_relcmp( sFirst, sSecond )
#
#   sFirst > sSecond : 1
#   sFirst = sSecond : 0
#   sFirst < sSecond : -1
#   sFirst != sSecond : nil
#
#   Copyright by Tadaaki Okabe <kabe@kabe.ac>
#

def m_vercmp( sFirst, sSecond )
  #
  # m_vercmp: 'version-releace' compare module
  #
  # sFirst > sSecond : 1
  # sFirst = sSecond : 0
  # sFirst < sSecond : -1
  # sFirst != sSecond : nil

  if ( (sFirst <=> sSecond) == 0 )
    return 0;
  end

  # asFirst/asSecond[0] : Version
  # asFirst/asSecond[1] : Release
  asFirst = sFirst.split( /-/ )[-2..-1]
  asSecond = sSecond.split( /-/ )[-2..-1]

  if ( (asFirst[0] <=> asSecond[0]) == 0 )
    ## Compare release, if sFirstVer == sSecondVer
    return m_relcmp( asFirst[1], asSecond[1] )
  end

  ## Compare Version
  asFirstVer = asFirst[0].scan( /([0-9a-zA-Z]*)([^0-9a-zA-Z]?)/ )
  asSecondVer = asSecond[0].scan( /([0-9a-zA-Z]*)([^0-9a-zA-Z]?)/ )
  asFirstVer.pop
  asSecondVer.pop

  asFirstVer.each do |asFV|
    asSV = asSecondVer.shift

    if ( (asFV[0] <=> asSV[0]) != 0 )
      asFV[0] = '0' << asFV[0]
      asSV[0] = '0' << asSV[0]
      asFC = asFV[0].scan ( /\d+|\D+/ )
      asSC = asSV[0].scan ( /\d+|\D+/ )

      until (asFC.empty? || asSC.empty?) do 
        sFC = asFC.shift
        sSC = asSC.shift
        bDigit = (( /\d+/ =~ sFC ) ? true : false) && \
                 (( /\d+/ =~ sSC ) ? true : false)

        if ( (sFC == "") && (sSC == "") )
          next
        else ## if ( (sFC != "") || (sSC != "") )
          if ( bDigit )
            vc = sFC.to_i <=> sSC.to_i
          else
            vc = sFC <=> sSC
          end

          if ( vc != 0 )
            return vc
          end
          if ( !asFC.empty? && !asSC.empty? )
            next
          end
          ## asFC.empty?  || asFC.empty? || vc == 0
          if ( asFV[1] == asFV[1] )
            ## (vc == 0) && (asFV[1] == asFV[2])  
            vc = (asFC.size <=> asSC.size) * (bDigit ? 1 : -1)
            if ( vc == 0 )
              vc = m_relcmp( asFirst[1], asSecond[1] )
            end
            return vc
          end
          if ( ((asSV[1] == "") || (asSV[1] != ".")) && (asFV[1] == ".") )
            return 1
          elsif ( (asSV[1] == "") && (asFV[1] != "") && (asFV[1] != ".") )
            return (-1)
          elsif ( ((asFV[1] == "") || (asFV[1] != ".")) && (asSV[1] == ".") )
            return (-1)
          elsif ( (asFV[1] == "") && (asSV[1] != "") && (asSV[1] != ".") )
            return 1
          end
        end
      end
    else ## asFV[0] == asSV[0]
      if ( ((asSV[1] == "") || (asSV[1] != ".")) && (asFV[1] == ".") )
        return 1
      elsif ( (asSV[1] == "") && (asFV[1] != "") && (asFV[1] != ".") )
        return (-1)
      elsif ( ((asFV[1] == "") || (asFV[1] != ".")) && (asSV[1] == ".") )
        return (-1)
      elsif ( (asFV[1] == "") && (asSV[1] != ".") && (asSV[1] != "") )
        return 1
      end
    end
  end
end

def m_relcmp( sFirst, sSecond )
  #
  # m_relcmp: 'releace' compare module
  #
  # sFirst > sSecond : 1
  # sFirst = sSecond : 0
  # sFirst < sSecond : -1
  # sFirst != sSecond : nil

  ## Compare release
  # Releace: n.nnkn or nkn (n is numeric)
  # 2002/04/11: (\d*^\d?)* (Regexp)
  asFRDig = sFirst.split( /[a-zA-Z_]+/ )
  sFRS = sFirst.scan( /[a-zA-Z_]+/ )
  asSRDig = sSecond.split( /[a-zA-Z_]+/ )
  sSRS = sSecond.scan( /[a-zA-Z_]+/ )

  if ( (sFRS <=> sSRS) != 0 )
    # if sFRS != sSRS, sSecond is newer 
    return -1
  end

  if ( (asFRDig[0] <=> asSRDig[0]) != 0 )
    return asFRDig[0].to_f <=> asSRDig[0].to_f
  else
    if ( (asFRDig.size == 2) && (asSRDig.size == 2) )
      return asFRDig[1].to_f <=> asSRDig[1].to_f
    elsif ( asFRDig.size == 2 )
      return 1
    elsif ( asSRDig.size == 2 )
      return -1
    else  ## sFirst != sSecond  
      ## if sFirst != sSecond, sSecond is newer  
      return -1
    end
  end
end

def m_ShowUsage()
  printf( "Usage:\n" )
  printf( "\t%s First Second\n", $0 )
end

require 'rpm'

if( ARGV.size != 2 )
  m_ShowUsage()
  exit( 0 )
end

puts 'First > Second : 1'
puts 'First = Second : 0'
puts 'First < Second : -1'

sFirst = ARGV.shift
sSecond = ARGV.shift

mvc1 = m_vercmp( sFirst, sSecond )
case mvc1
when 0
  mvs1 = "="
else
  mvs1 = ( mvs1 > 0 ) ? ">" : "<"
end

rvc1 = RPM::vercmp( sFirst, sSecond )
case rvc1
when 0
  rvs1 = "="
else
  rvs1 = ( rvc1 > 0 ) ? ">" : "<"
end

mvc2 = m_vercmp( sSecond, sFirst )
case mvc2
when 0
  mvs2 = "="
else
  mvs2 = ( mvs2 > 0 ) ? ">" : "<"
end

rvc2 = RPM::vercmp( sSecond, sFirst )
case rvc2
when 0
  rvs2 = "="
else
  rvs2 = ( rvc2 > 0 ) ? ">" : "<"
end

printf ( "\n----  %s  <=>  %s  ----\n", sFirst, sSecond )
printf ( "   m_vercmp( %s , %s ) = %i ( %s )\n", sFirst, sSecond, mvc1, mvs1 )
printf ( "RPM::vercmp( %s , %s ) = %i ( %s )\n", sFirst, sSecond, rvc1, rvs1 )

printf ( "\n----  %s  <=>  %s  ----\n", sSecond, sFirst )
printf ( "   m_vercmp( %s , %s ) = %i ( %s )\n", sSecond, sFirst, mvc2, mvs2 )
printf ( "RPM::vercmp( %s , %s ) = %i ( %s )\n\n", sSecond, sFirst, rvc2, rvs2 )
