import React, {Component} from 'react';
import $ from 'jquery';
import endpoints from './endpoints';
import LoadingWidget from './components/LoadingWidget';
import * as utils from './utils';

function loadFromAPI(endpoint, callback) {
    if (typeof endpoint !== "string")
        throw new Error("Invalid endpoint argument");
    if (typeof callback !== "function")
        throw new Error("Invalid callback argument");

    let url = endpoints.apiBaseURL + "/" + endpoint;
    if (utils.isNotProduction())
        console.log("Sending dynamic request for", url);

    $.ajax({
        url: url,
        success: function(data) {
            callback(data);
        },
        dataType: "json"
    });
}

// This is an abstract base class for components which load data dynamically from the API.
class DynamicComponent extends Component {
    constructor(props) {
        super(props);
        this.state = {
            dynamicData: {}
        }
    }

    // To be defined in child class
    // Returns: an object mapping {endpoint_name: endpoint_url}
    getEndpoints(props) {
        throw new Error("getEndpoints not implemented");
    }

    componentWillReceiveProps(newProps) {
        // Detect if the endpoints have changed and if so reload
        let oldEndpoints = this.getEndpoints(this.props);
        let newEndpoints = this.getEndpoints(newProps);

        for (let name in oldEndpoints) {
            if (oldEndpoints.hasOwnProperty(name)) {
                let oldEp = oldEndpoints[name];
                let newEp = newEndpoints[name];

                if (oldEp !== newEp) {
                    this.loadEndpoint(name, newEp);
                }
            }
        }
    }

    componentWillMount() {
        let endpoints = this.getEndpoints(this.props);

        for (let name in endpoints) {
            if (endpoints.hasOwnProperty(name)) {
                let ep = endpoints[name];
                this.loadEndpoint(name, ep);
            }
        }
    }

    loadEndpoint(endpointName, endpointUrl) {
        let self = this; // necessary to save a reference for use in the callback below
        loadFromAPI(endpointUrl, function(data) {
            if (utils.isNotProduction())
                console.log("dynamicData", endpointName, data);
            self.setState(Object.assign(self.state.dynamicData, {[endpointName]: data}));
        });
    }

    isDynamicDataLoaded(endpointName) {
        return this.state.dynamicData[endpointName] !== undefined;
    }

    isAllDynamicDataLoaded() {
        let allNames = Object.keys(this.getEndpoints(this.props));
        for (let name of allNames) {
            if (!this.isDynamicDataLoaded(name))
                return false;
        }
        return true;
    }

    getDynamicData(endpointName) {
        return this.state.dynamicData[endpointName];
    }

    getLoadingDynamicContent() {
        return <LoadingWidget />;
    }

    // Content to be shown in place of actual content if the API fails to load
    getFailedDynamicContent() {
        return this.getLoadingDynamicContent();
        //return <div className="api-load-failure">This content failed to load.</div>;
    }
}

export default DynamicComponent;
