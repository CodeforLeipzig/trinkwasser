package generator

import com.fasterxml.jackson.databind.ObjectMapper
import java.io.BufferedWriter
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.util.Map
import org.geojson.Feature
import org.geojson.FeatureCollection

import static extension generator.GeneratorMain.getGemeinde
import static extension generator.GeneratorMain.getNatrium
import static extension generator.GeneratorMain.getKalium
import static extension generator.GeneratorMain.getCalcium
import static extension generator.GeneratorMain.getMagnesium
import static extension generator.GeneratorMain.getHardness
import static extension generator.GeneratorMain.getHardnessRange
import static extension generator.GeneratorMain.getHardnessMMO
import static extension generator.GeneratorMain.getConductability
import static extension generator.GeneratorMain.getPHValue

class GeoJSONReducerMain {
   
   def static void main(String[] args) {
      val inputStream = new FileInputStream(new File("C:\\Users\\Joerg\\Desktop\\osm_relations_full.geojson"))
      val featureCollection = new ObjectMapper().readValue(inputStream, FeatureCollection)
      inputStream.close
      
      
      val keysAndValues = GeneratorMain.getKeysAndValues("E:/Arbeit/OKLab/OpenDataDay/trinkwasser_daten/TW-Quali_230217.csv")
      val keys = keysAndValues.key
      val valuesList = keysAndValues.value
      
      val newFeatureCollection = new FeatureCollection
      val notHandled = newArrayList
      for(values : valuesList) {
         val gemeinde = values.getGemeinde(keys)
         val feature = featureCollection.features.filter[(it.properties?.get("tags") as Map<String, String>)?.get("name")?.equals(gemeinde)].head
         if(feature !== null) {
            val newFeature = new Feature => [
               properties.put("tags", newHashMap => [
                  put("name", gemeinde)
                  put("natrium", values.getNatrium(keys))
                  put("kalium", values.getKalium(keys))
                  put("calcium", values.getCalcium(keys))
                  put("magnesium", values.getMagnesium(keys))
                  put("hardness", values.getHardness(keys))
                  put("hardnessRange", values.getHardnessRange(keys))
                  put("hardnessMMO", values.getHardnessMMO(keys))
                  put("conductability", values.getConductability(keys))
                  put("phValue", values.getPHValue(keys))
               ])
               id = feature.id
               geometry = feature.geometry
            ]
            newFeatureCollection.add(newFeature)
         } else {
         	notHandled.add(gemeinde)
         }
      }
      
      notHandled.forEach[println]
      println("available")
      featureCollection.features.map[(it.properties?.get("tags") as Map<String, String>)?.get("name")].forEach[println]
      
      val json = new ObjectMapper().writeValueAsString(newFeatureCollection);
      val file = new File("out.geojson")
      val fw = new BufferedWriter(new OutputStreamWriter(
         new FileOutputStream(file), "UTF8"))
      fw.write(json)
      fw.flush
      fw.close
   }
}