import React, {Component} from 'react';
import $ from 'jquery';
import endpoints from './endpoints';

function getCurrentUnixTimeSecs() {
    return Math.floor((new Date()).getTime() / 1000);
}

function loadFromAPI(endpoint, callback) {
    if (typeof endpoint !== "string")
        throw new Error("Invalid endpoint argument");
    if (typeof callback !== "function")
        throw new Error("Invalid callback argument");

    $.ajax({
        url: endpoints.apiBaseURL + "/" + endpoint,
        success: function(data) {
            callback(data);
        },
        dataType: "json"
    });
}

// This is an abstract base class for components which load data dynamically from the API.
// The constructor takes a parameter 'endpoint' which is the endpoint on the server to access to retrieve the neccessary data.
class DynamicComponent extends Component {
    constructor(props) {
        super(props);
        this.state = {
            dynamicData: null
        }
    }

    // To be defined in child class
    getEndpoint(props) {
    }

    componentWillReceiveProps(newProps) {
        let oldEndpoint = this.getEndpoint(this.props);
        let newEndpoint = this.getEndpoint(newProps);
        if (oldEndpoint !== newEndpoint) {
            this.reloadDynamicData(newEndpoint);
        }
    }

    componentWillMount() {
        this.reloadDynamicData(this.getEndpoint(this.props));
    }

    reloadDynamicData(endpoint) {
        let self = this; // neccessary to save a 'this' reference for use in the callback below
        loadFromAPI(endpoint, function(data) {
            self.setState({dynamicData: data});
            self.onAPIDataLoaded(data);
        });
    }

    // To be defined in child class
    onAPIDataLoaded(data) {
        //console.log("onAPIDataLoaded", this);
    }

    isAPIDataLoaded() {
        return this.state.dynamicData != null;
    }

    // Content to be shown in place of actual content if the API fails to load
    getFailedAPIContent() {
        return <div className="api-load-failure">API failed to load.</div>;
    }
}

export default DynamicComponent;
