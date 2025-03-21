console.log('Google.js loaded');

let map;
let marker;
let autocomplete;
let currentPropertyId; // Variable to store the current property ID

function initMap() {
    console.log('Initializing map...');
    
    const mapDiv = document.getElementById('map');
    if (!mapDiv) {
        console.error('Map container not found');
        return;
    }
    
    try {
        const defaultLocation = { lat: -30.5595, lng: 22.9375 };
        
        map = new google.maps.Map(mapDiv, {
            center: defaultLocation,
            zoom: 5,
            mapTypeControl: true,
            streetViewControl: true,
            mapTypeId: google.maps.MapTypeId.ROADMAP
        });

        console.log('Map initialized');

        marker = new google.maps.Marker({
            map: map,
            draggable: true,
            animation: google.maps.Animation.DROP
        });

        initAutocomplete();

    } catch (error) {
        console.error('Error initializing map:', error);
    }
}

function initAutocomplete() {
    console.log('Initializing autocomplete...');
    
    const input = document.getElementById('street_address');
    if (!input) {
        console.error('Street address input not found!');
        return;
    }

    autocomplete = new google.maps.places.Autocomplete(input, {
        types: ['address'],
        componentRestrictions: { country: ['za'] },
        fields: ['address_components', 'geometry', 'formatted_address']
    });

    autocomplete.bindTo('bounds', map);

    autocomplete.addListener('place_changed', function() {
        const place = autocomplete.getPlace();
        console.log('Place selected:', place);

        if (!place.geometry || !place.geometry.location) {
            alert('No details available for this place');
            return;
        }

        // Update the map location and associate with property_id
        updateMapLocation(place.geometry.location, currentPropertyId);
        fillInAddress(place);
    });
}

function updateMapLocation(location, propertyId) {
    map.setCenter(location);
    map.setZoom(17);
    marker.setPosition(location);
    marker.setVisible(true);
    
    // Associate the marker with the property ID
    marker.propertyId = propertyId; // Store property ID in marker
    updateFormCoordinates(location);
}

function updateFormCoordinates(location) {
    document.getElementById('latitude').value = location.lat();
    document.getElementById('longitude').value = location.lng();
}

function fillInAddress(place) {
    clearFormFields();

    for (const component of place.address_components) {
        const componentType = component.types[0];
        
        switch (componentType) {
            case 'street_number':
                document.getElementById('door_number').value = component.long_name;
                break;
            case 'route':
                document.getElementById('street_address').value = component.long_name;
                break;
            case 'sublocality':
            case 'sublocality_level_1':
                document.getElementById('suburb').value = component.long_name;
                break;
            case 'locality':
                document.getElementById('city').value = component.long_name;
                break;
            case 'administrative_area_level_1':
                document.getElementById('state_id').value = component.long_name; // Set state name
                break;
            case 'country':
                document.getElementById('country_id').value = component.long_name; // Set country name
                break;
            case 'postal_code':
                document.getElementById('zip_code').value = component.long_name; // Set zip code
                break;
        }
    }

    // Set the full formatted address
    document.getElementById('street_address').value = place.formatted_address;
}

function clearFormFields() {
    const fields = ['door_number', 'suburb', 'city', 'state_id', 'country_id', 'zip_code'];
    fields.forEach(field => {
        const element = document.getElementById(field);
        if (element) {
            element.value = '';
        }
    });
}

function displayError(message) {
    window.alert(message);
}

// Make sure initMap is globally available
window.initMap = initMap;

// Handle window resize
window.addEventListener('resize', function() {
    if (map) {
        google.maps.event.trigger(map, 'resize');
        const position = marker.getPosition();
        if (position) {
            map.setCenter(position);
        }
    }
});

// Add debugging code at the end
document.addEventListener('DOMContentLoaded', function() {
    console.log('DOM loaded');
    console.log('Google Maps API Key:', window.GOOGLE_MAPS_API_KEY);
    console.log('Map element:', document.getElementById('map'));
    console.log('Street address input:', document.getElementById('street_address'));
});

// Add this at the end
window.onerror = function(msg, url, lineNo, columnNo, error) {
    console.error('Error: ' + msg + '\nURL: ' + url + '\nLine: ' + lineNo + '\nColumn: ' + columnNo + '\nError object: ' + JSON.stringify(error));
    return false;
};
