package generator

import com.fasterxml.jackson.databind.ObjectMapper
import com.vividsolutions.jts.geom.Coordinate
import com.vividsolutions.jts.geom.CoordinateSequence
import com.vividsolutions.jts.geom.Geometry
import com.vividsolutions.jts.geom.GeometryFactory
import com.vividsolutions.jts.geom.impl.CoordinateArraySequenceFactory
import com.vividsolutions.jts.simplify.TopologyPreservingSimplifier
import java.io.BufferedWriter
import java.io.ByteArrayInputStream
import java.io.File
import java.io.FileOutputStream
import java.io.OutputStreamWriter
import java.util.List
import java.util.Map
import java.util.Scanner
import org.geojson.Feature
import org.geojson.FeatureCollection
import org.geojson.LngLatAlt
import org.geojson.Polygon

import static extension generator.GeneratorMain.getAverage
import static extension generator.GeneratorMain.getCalcium
import static extension generator.GeneratorMain.getConductability
import static extension generator.GeneratorMain.getGemeinde
import static extension generator.GeneratorMain.getOrtsteil
import static extension generator.GeneratorMain.getHardness
import static extension generator.GeneratorMain.getHardnessMMO
import static extension generator.GeneratorMain.getHardnessRange
import static extension generator.GeneratorMain.getKalium
import static extension generator.GeneratorMain.getMagnesium
import static extension generator.GeneratorMain.getMostFrequent
import static extension generator.GeneratorMain.getNatrium
import static extension generator.GeneratorMain.getPHValue
import java.util.HashMap

class GeoJSONReducerMain {
	
	private static final Map<String, String> GEMEINDE_MAPPING = #{
		"Köthen" -> "Köthen (Anhalt)",
		"Lutherstadt Eisleben" -> "Eisleben",
		"Lutherstadt Wittenberg" -> "Wittenberg",
		"Nienburg" -> "Nienburg (Saale)"
	}

	def static void main(String[] args) {
      	val file = new File("F:/Arbeit/OKLab/OpenDataDay/Trinkwasser/osm_relations_full.geojson")
      	val scanner = new Scanner(file, "ISO-8859-15")
      	scanner.useDelimiter("\\Z")
      	val inputStream = new ByteArrayInputStream(scanner.next.getBytes("UTF-8"));
	    scanner.close
		val featureCollection = new ObjectMapper().readValue(inputStream, FeatureCollection)
		inputStream.close

		val keysAndValues = GeneratorMain.getKeysAndValues(
			"F:/Arbeit/OKLab/OpenDataDay/Trinkwasser/trinkwasser_daten/TW-Quali_230217.csv")
		val keys = keysAndValues.key
		val valuesList = keysAndValues.value

		val newFeatureCollection = new FeatureCollection
		val notHandled = newArrayList
		
		val handledGemeinden = newHashMap
		
		for (values : valuesList) {
			val gemeinde = values.getGemeinde(keys).mapGemeindeName
			if(gemeinde !== null) {
				if(!handledGemeinden.containsKey(gemeinde)) {
					val feature = featureCollection.features.filter [
						gemeinde.equals((it.properties?.get("tags") as Map<String, String>)?.get("name"))
					].head
					if (feature !== null) {
						val newFeature = new Feature => [
							id = feature.id
							properties.put("tags", newHashMap => [
								put("name", gemeinde)
							])
							geometry = {
								if (feature.geometry instanceof Polygon) {
									val polygon = feature.geometry as Polygon
									val result = polygon.coordinates.map[simplifyCoords]
									polygon.coordinates = result
								}
								feature.geometry
							}
						]
						handledGemeinden.put(gemeinde, newFeature) 
						println('''processed: «gemeinde»''')
					} else {
						notHandled.add(gemeinde)
					}
				}
				val feature = handledGemeinden.get(gemeinde)
				val tags = feature.properties.get("tags") as HashMap<String, Object>
				if(!tags.containsKey("ortsteile")) {
					tags.put("ortsteile", newHashMap)
				}
				val ortsteile = tags.get("ortsteile") as HashMap<String, HashMap<String, Object>>
				val ortsteil = values.getOrtsteil(keys)
				ortsteile.put(ortsteil, newHashMap => [
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
			}
		}
		
		handledGemeinden.entrySet.forEach[value.setAverageValues]
		handledGemeinden.entrySet.forEach[newFeatureCollection.add(value)]

		println("\nnot handled:")
		notHandled.toSet.forEach[println(it)]

		val json = new ObjectMapper().writeValueAsString(newFeatureCollection);
		val out = new File("sachsen-anhalt.geojson")
		val fos = new FileOutputStream(out)
		val osw = new OutputStreamWriter(fos, "UTF8")
		val fw = new BufferedWriter(osw)
		fw.write(json)
		fw.flush
		fw.close
		osw.close
		fos.close
	}
	
	private static def setAverageValues(Feature feature) {
		val tags = feature.properties.get("tags") as HashMap<String, Object>
		val ortsteile = tags.get("ortsteile") as HashMap<String, HashMap<String, Object>>
		tags.transformDoubles(ortsteile, "natrium")
		tags.transformStrings(ortsteile, "hardnessRange")
		tags.transformDoubles(ortsteile, "calcium")
		tags.transformDoubles(ortsteile, "magnesium")
		tags.transformDoubles(ortsteile, "natrium")
		tags.transformDoubles(ortsteile, "kalium")
	}
	
	private static def transformDoubles(HashMap<String, Object> tags, HashMap<String, HashMap<String, Object>> ortsteile, String key) {
		tags.put(key, ortsteile.values.map[get(key)].map[String.valueOf(it)].getAverage)
	}

	private static def transformStrings(HashMap<String, Object> tags, HashMap<String, HashMap<String, Object>> ortsteile, String key) {
		tags.put(key, ortsteile.values.map[get(key)].map[String.valueOf(it)].getMostFrequent)
	}
	
	private static def mapGemeindeName(String gemeinde) {
		if (GEMEINDE_MAPPING.containsKey(gemeinde)) 
			GEMEINDE_MAPPING.get(gemeinde) 
		else gemeinde
	}
	
	
	private static def toCoordinate(LngLatAlt coord) {
		new Coordinate(coord.latitude, coord.longitude)
	}
	
	private static def toCoordSequence(List<Coordinate> coords) {
		CoordinateArraySequenceFactory.instance.create(coords)
	}

	private static def toGeometry(CoordinateSequence coordSeq) {
		new GeometryFactory().createPolygon(coordSeq)
	}

	private static def reduceGeometry(Geometry geometry) {
		val bbox = geometry.getEnvelopeInternal
        var latMax = Math.max(Math.abs(bbox.getMaxY),Math.abs(bbox.getMinY))
		var reduced = TopologyPreservingSimplifier.simplify(geometry, latMax);
		var diff = 0
		var oldDiff = -1d
		var distanceTolerance = 0d;
		var unchangedCount = 0
		while((diff == 0 || unchangedCount < 20) && distanceTolerance < latMax) {
			oldDiff = diff
			distanceTolerance = distanceTolerance + 0.00001
			reduced = TopologyPreservingSimplifier.simplify(geometry, distanceTolerance);
			val newDiff = geometry.coordinates.size - reduced.coordinates.size
			if(newDiff > oldDiff) {
				diff = newDiff
				unchangedCount = 0
			} else {
				unchangedCount++
			}
		}
		reduced
	}
	
	private static def toLngLatAlt(Coordinate coord) {
		new LngLatAlt(coord.y, coord.x)
	}
	
	private static def simplifyCoords(List<LngLatAlt> coords) {
		coords.map[toCoordinate].toCoordSequence.toGeometry.reduceGeometry
			.coordinates.map[toLngLatAlt]
	}
}
