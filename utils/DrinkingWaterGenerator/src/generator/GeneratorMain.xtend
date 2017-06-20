package generator

import java.io.BufferedWriter
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.text.DecimalFormat
import java.text.NumberFormat
import java.util.Arrays
import java.util.List
import java.util.Locale
import java.util.Scanner

class GeneratorMain {
   
   def static void main(String[] args) {
      val inputFile = args.get(0)
      generateTrinkwasserJS(inputFile)
      generateTrinkwasserLocationJS(inputFile)
   }

   static def Pair<List<String>, List<List<String>>> getKeysAndValues(String inputFile) {
      val file = new File(inputFile)
      val scanner = new Scanner(file, "ISO-8859-15")
      scanner.useDelimiter("\n")
      val headline = if(scanner.hasNext) scanner.next else ""
      val keys = headline.split(';')
      val valuesList = newArrayList
      while(scanner.hasNext) {
         val line = scanner.next
         val values = Arrays.asList(line.split(';'))
         valuesList.add(values)
      }
      scanner.close
      Pair.of(keys, valuesList)
   }
   
   static def generateGemeindeList(String inputFile) {
      val file = new File(inputFile)
      val scanner = new Scanner(file, "ISO-8859-15")
      scanner.useDelimiter("\n")
      val headline = if(scanner.hasNext) scanner.next else ""
      val keys = headline.split(';')
      val valuesList = newArrayList
      while(scanner.hasNext) {
         val line = scanner.next
         val values = line.split(';')
         valuesList += values
      }
      scanner.close
      valuesList.map[getGemeinde(keys)].toSet
   }
   
   
   static def generateTrinkwasserLocationJS(String inputFile) {
      val file = new File(inputFile)
      val scanner = new Scanner(file, "ISO-8859-15")
      scanner.useDelimiter("\n")
      val headline = if(scanner.hasNext) scanner.next else ""
      val untransformedKeys = headline.split(';')
      val keys = newArrayList
      for(i : 0..untransformedKeys.size-1) {
         if(untransformedKeys.get(i).equals("Einh.")) {
            keys.add(untransformedKeys.get(i-1).trim + " Einh.")
         } else {
            keys.add(untransformedKeys.get(i).trim)
         }
      }
      val valuesList = newArrayList
      while(scanner.hasNext) {
         val line = scanner.next
         val values = line.split(';')
         valuesList += values
      }
      scanner.close
      
      val gemeindeToOrtsteil = valuesList.map[getGemeinde(keys) -> getOrtsteil(keys)].toSet
      val map = newHashMap
      for(entry : gemeindeToOrtsteil.sortBy[key]) {
         var List<String> set = map.get(entry.key)
         if(set === null) {
            set = newArrayList
         }
         set.add(entry.value)
         set = set.sort
         map.put(entry.key, set) 
      }
      val gen = '''
         tw.data.locations = {
            «FOR gemeinde : map.keySet.sort SEPARATOR ','»
               "«gemeinde»": {
                  «FOR ortsteil : map.get(gemeinde).sort SEPARATOR ','»
                     "«ortsteil»": {}
                  «ENDFOR»
               }
            «ENDFOR»
         }
      '''
      writeFile("locations-sachsen-anhalt.js", gen)      
   }

   static def generateTrinkwasserJS(String inputFile) {
      val file = new File(inputFile)
      val scanner = new Scanner(file, "ISO-8859-15")
      scanner.useDelimiter("\n")
      val headline = if(scanner.hasNext) scanner.next else ""
      val untransformedKeys = headline.split(';')
      val keys = newArrayList
      for(i : 0..untransformedKeys.size-1) {
         if(untransformedKeys.get(i).equals("Einh.")) {
            keys.add(untransformedKeys.get(i-1).trim + " Einh.")
         } else {
            keys.add(untransformedKeys.get(i).trim)
         }
      }
      val valuesList = newArrayList
      while(scanner.hasNext) {
         val line = scanner.next
         val values = line.split(';')
         valuesList += values
      }
      scanner.close
      val gen = '''
         tw.data.zones = {
            «FOR values : valuesList SEPARATOR ','»
               "«values.getGemeinde(keys)»«values.getOrtsteilIfRequired(keys)»": {
                  "natrium": «values.getNatrium(keys)»,
                  "kalium": «values.getKalium(keys)»,
                  "calcium": «values.getCalcium(keys)»,
                  "magnesium": «values.getMagnesium(keys)»,
«««                  "chlorid": «values.getChlorid(keys)»,
«««                  "nitrat": «values.getNitrat(keys)»,
«««                  "sulfat": «values.getSulfat(keys)»,
                  "hardness": «values.getHardness(keys)»,
                  // extra values
                  "hardnessRange": "«values.getHardnessRange(keys)»",
                  "hardnessMMO": «values.getHardnessMMO(keys)»,
                  "conductability": «values.getConductability(keys)»,
                  "phValue": «values.getPHValue(keys)»,
                  "year": 2016,
                  "description": ""
               }
           «ENDFOR»
         };
         tw.data.averageValues = {
             "natrium": «valuesList.map[getNatrium(keys)].getAverage»,
             "kalium": «valuesList.map[getKalium(keys)].getAverage»,
             "calcium": «valuesList.map[getCalcium(keys)].getAverage»,
             "magnesium": «valuesList.map[getMagnesium(keys)].getAverage»,
«««             "chlorid": 22.2,
«««             "nitrat": 4.5,
«««             "sulfat": 32.1,
             "hardness": «valuesList.map[getHardness(keys)].getAverage»
         };
      '''
      writeFile("zones-sachsen-anhalt.js", gen)      
   }
   
   def static getAverage(Iterable<String> values) {
      val doubleValues = values.map[Double.valueOf(it)]
      val count = doubleValues.size
      val nf = NumberFormat.getNumberInstance(Locale.ENGLISH);
      val df = nf as DecimalFormat;
      df.applyPattern("0.00");
      return df.format(doubleValues.reduce[v1, v2|v1 + v2] / count)
   }
   
   def static getMostFrequent(Iterable<String> values) {
   	  values.groupBy[it].entrySet.map[key -> value.size].sortBy[value].map[key].head	
   }   
   
   def static getGemeinde(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Gemeinde")
   }

   def static getOrtsteil(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Ortsteil")
   }

   def static getOrtsteilIfRequired(List<String> values, List<String> keys) {
      val gemeinde = getGemeinde(values, keys)
      val ortsteil = values.getValueForKey(keys, "Ortsteil")
      return if(gemeinde.equals(ortsteil)) "" else " " + ortsteil
   }

   def static getNatrium(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Natrium")
   }

   def static getKalium(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Kalium")
   }

   def static getCalcium(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Calcium")
   }

   def static getMagnesium(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Magnesium")
   }

   def static getHardness(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Härte")
   }

   def static getHardnessRange(List<String> values, List<String> keys) {
      val value = values.getValueForKey(keys, "Härtebereich")
      val convertedValue = switch (value) {
         case "weich": "soft",
         case "hart": "hard"
         default: "unknown"         
      }
      return convertedValue;
   }

   def static getHardnessMMO(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Härte (mmo)")
   }

   def static getConductability(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "Leitfähigkeit")
   }

   def static getPHValue(List<String> values, List<String> keys) {
      return values.getValueForKey(keys, "PH-Wert")
   }

   def static getValueForKey(List<String> values, List<String> keys, String key) {
      val index = keys.indexOf(key)
      if(index >= 0) {
         return values.get(index).replace(',', '.').trim
      } else {
         return "unknown"
      }
   }
   
   static def writeFile(String fileName, CharSequence content) {
      val dir = new File("src-gen")
      dir.mkdirs
      val file = new File("src-gen/" + fileName)
      val fw = new BufferedWriter(new OutputStreamWriter(
         new FileOutputStream(file), "UTF8"));
      fw.write(content.toString)
      fw.flush
      fw.close
   }
}
